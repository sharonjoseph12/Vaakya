import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/local_db.dart';
import '../models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String _lastTopic = '';
  VoidCallback? onNewMessage;
  void Function(String subject)? onQuestionTracked;
  void Function(String subject)? onQuizRequested;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;

  Future<String?> sendMessage({required String query, required String profileId, String subject = 'General', String language = 'en-IN', String learnerLevel = 'Intermediate', String userName = 'Student'}) async {
    _messages.add(MessageModel.user(query));
    _isLoading = true;
    notifyListeners();
    _notifyNewMessage();
    onQuestionTracked?.call(subject);

    // Detect "quiz me" command
    final ql = query.toLowerCase();
    if (ql.contains('quiz me') || ql.contains('test me') || ql.contains('quiz') && ql.contains('start')) {
      final topic = ql.replaceAll(RegExp(r'quiz me on|test me on|quiz me|test me|start quiz'), '').trim();
      _isLoading = false;
      final reply = '🎯 Starting a quiz${topic.isNotEmpty ? " on $topic" : ""}! Opening quiz screen...';
      _messages.add(MessageModel.ai(reply));
      notifyListeners();
      _notifyNewMessage();
      onQuizRequested?.call(topic.isNotEmpty ? topic : subject);
      return reply;
    }

    // Seed offline DB
    await LocalDatabase.instance.seedIfNeeded();

    String? aiReply;
    String? sourcePage;

    // Try backend (fast — 3s timeout, skips if known down)
    final response = await ApiClient.askQuestion(profileId: profileId, query: query, subject: subject, language: language, learnerLevel: learnerLevel);
    if (response != null) {
      aiReply = response['ai_reply'] as String?;
      sourcePage = response['source_textbook_page'] as String?;
      if (aiReply != null) await LocalDatabase.instance.cacheResponse(query: query, answer: aiReply, language: language);
      _isOffline = false;
    }

    // Fallback chain: offline cache → faculty notes → smart fallback
    if (aiReply == null) {
      aiReply = await LocalDatabase.instance.searchOffline(query);
      if (aiReply == null) {
        // Search faculty-uploaded notes
        final facultyContent = await LocalDatabase.instance.getAllFacultyContent();
        if (facultyContent.isNotEmpty) {
          final words = query.toLowerCase().split(' ').where((w) => w.length > 3);
          for (final w in words) {
            if (facultyContent.toLowerCase().contains(w)) {
              // Extract relevant paragraph
              final idx = facultyContent.toLowerCase().indexOf(w);
              final start = (idx - 200).clamp(0, facultyContent.length);
              final end = (idx + 400).clamp(0, facultyContent.length);
              aiReply = '📖 From your teacher\'s notes:\n\n${facultyContent.substring(start, end).trim()}\n\n💡 Tip: Review the full notes in Study Materials for more context. Would you like me to explain any part in more detail?';
              break;
            }
          }
        }
        if (aiReply == null) {
          final fb = _smartFallback(query, userName, language);
          aiReply = fb?.reply;
          sourcePage = fb?.youtubeUrl;
        }
      }
      _isOffline = !ApiClient.shouldTryBackend;
    }

    aiReply ??= "That is a great question, $userName! Could you try rephrasing it?";

    // Auto-attach YouTube video if none from backend
    sourcePage ??= _autoYoutube(query);

    _messages.add(MessageModel.ai(aiReply, sourcePage: sourcePage));
    _isLoading = false;
    notifyListeners();
    _notifyNewMessage();
    return aiReply;
  }

  /// Maps keywords to relevant YouTube educational videos
  static String? _autoYoutube(String query) {
    final q = query.toLowerCase();
    const map = {
      'trigonometry,sin,cos,tan,angle': 'https://www.youtube.com/watch?v=PUB0TaZ7bhA',
      'photosynthesis,chlorophyll,plant,leaf': 'https://www.youtube.com/watch?v=UPBMG5EYydo',
      'newton,gravity,force,motion,inertia': 'https://www.youtube.com/watch?v=kKKM8Y-u7ds',
      'cell,mitochondria,nucleus,organelle': 'https://www.youtube.com/watch?v=URUJD5NEXC8',
      'algebra,equation,quadratic,polynomial': 'https://www.youtube.com/watch?v=IlNAJl36-10',
      'atom,element,periodic,proton,electron': 'https://www.youtube.com/watch?v=rz4Dd1I_fX0',
      'water,cycle,evaporation,rain': 'https://www.youtube.com/watch?v=al-do-HGuIk',
      'acid,base,ph,chemical,reaction': 'https://www.youtube.com/watch?v=vt8fB3PC4ts',
      'electricity,circuit,current,voltage,ohm': 'https://www.youtube.com/watch?v=mc979OhitAg',
      'light,optics,lens,mirror,reflection': 'https://www.youtube.com/watch?v=Oh4m8Ees-3Q',
      'fraction,decimal,percentage,ratio': 'https://www.youtube.com/watch?v=n0FZhQ_GkKw',
      'history,war,revolution,empire,king': 'https://www.youtube.com/watch?v=xuCn8ux2gbs',
      'geography,continent,climate,ocean': 'https://www.youtube.com/watch?v=x7k-bMA-l2Q',
      'english,grammar,tense,sentence': 'https://www.youtube.com/watch?v=jCa-2ItBjd4',
    };
    for (final entry in map.entries) {
      if (entry.key.split(',').any((k) => q.contains(k))) return entry.value;
    }
    return 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
  }

  void addAiMessage(String text) { _messages.add(MessageModel.ai(text)); notifyListeners(); _notifyNewMessage(); }
  void addUserMessage(String text) { _messages.add(MessageModel.user(text)); notifyListeners(); _notifyNewMessage(); }
  void clearChat() { _messages.clear(); _lastTopic = ''; notifyListeners(); }

  _FB? _smartFallback(String query, String name, String lang) {
    final q = query.toLowerCase();

    // ── HINGLISH (Hindi written in English) ──
    if (_isHinglish(q)) {
      if (q.contains('photosynthesis') || q.contains('prakash')) return _t('photosynthesis', '$name, प्रकाश संश्लेषण (Photosynthesis) वह अद्भुत प्रक्रिया है जिसके द्वारा हरे पौधे सूर्य के प्रकाश का उपयोग करके अपना भोजन बनाते हैं।\n\n📌 मुख्य रासायनिक समीकरण:\n6CO₂ + 6H₂O + Sunlight → C₆H₁₂O₆ + 6O₂\n\nयह प्रक्रिया मुख्य रूप से पत्तियों के \'क्लोरोप्लास्ट\' (Chloroplast) में होती है, जहाँ \'क्लोरोफिल\' (Chlorophyll) सूर्य की रोशनी को सोखता है। इसी वजह से पौधे हमें जीवनदायी ऑक्सीजन देते हैं!\n\n💡 Hint: क्लोरोफिल ही पत्तियों को हरा रंग देता है।\n\nक्या आप जानना चाहते हैं कि इस प्रक्रिया में पानी (H₂O) की क्या भूमिका है?', yt: 'https://www.youtube.com/watch?v=UPBMG5EYydo');
      if (q.contains('trigonometry') || q.contains('trikon')) return _t('trigonometry', '$name, त्रिकोणमिति (Trigonometry) गणित की वह शाखा है जो त्रिभुज के कोणों (angles) और भुजाओं (sides) के बीच के संबंध का अध्ययन करती है।\n\n📌 समकोण त्रिभुज (Right-Angled Triangle) के मुख्य अनुपात (SOH CAH TOA):\n1. Sine (Sin θ) = लंब (Opposite) / कर्ण (Hypotenuse)\n2. Cosine (Cos θ) = आधार (Adjacent) / कर्ण (Hypotenuse)\n3. Tangent (Tan θ) = लंब (Opposite) / आधार (Adjacent)\n\n⚡ महत्वपूर्ण मान:\n• Sin 30° = 0.5\n• Sin 45° = 1/√2\n• Sin 90° = 1\n\n💡 Hint: त्रिकोणमिति का उपयोग इमारतों की ऊँचाई नापने या अंतरिक्ष विज्ञान में होता है।\n\nक्या मैं आपको इसका एक उदाहरण देकर समझाऊं?', yt: 'https://www.youtube.com/watch?v=PUB0TaZ7bhA');
      if (q.contains('newton') || q.contains('gravity') || q.contains('gurutva') || q.contains('force')) return _t('newton', '$name, सर आइजैक न्यूटन ने गति (Motion) के 3 बहुत ही महत्वपूर्ण नियम दिए हैं:\n\n1️⃣ जड़त्व का नियम (Inertia): कोई भी वस्तु तब तक स्थिर या गति में रहती है, जब तक उस पर कोई बाहरी बल (Force) न लगाया जाए।\n2️⃣ F = ma: बल (Force) = द्रव्यमान (Mass) × त्वरण (Acceleration)। भारी वस्तु को धकेलने के लिए अधिक बल चाहिए।\n3️⃣ क्रिया-प्रतिक्रिया (Action-Reaction): हर क्रिया के बराबर और विपरीत प्रतिक्रिया होती है (जैसे रॉकेट का उड़ना)।\n\n📌 गुरुत्वाकर्षण (Gravity): पृथ्वी पर गुरुत्वीय त्वरण (g) = 9.8 m/s² होता है।\n\nक्या आप गति के तीसरे नियम का कोई और उदाहरण जानना चाहते हैं?', yt: 'https://www.youtube.com/watch?v=kKKM8Y-u7ds');
      if (q.contains('cell') || q.contains('koshika')) return _t('cell', '$name, कोशिका (Cell) हमारे शरीर और सभी जीवित जीवों की सबसे छोटी और मूलभूत इकाई (Building Block) है।\n\n🔬 कोशिका के मुख्य अंग (Organelles):\n• केंद्रक (Nucleus): यह कोशिका का "मस्तिष्क" है जो DNA को सुरक्षित रखता है।\n• माइटोकॉन्ड्रिया (Mitochondria): यह कोशिका का "पावरहाउस" है जो ऊर्जा (ATP) बनाता है।\n• कोशिका झिल्ली (Cell Membrane): यह तय करती है कि कोशिका के अंदर क्या जाएगा और क्या बाहर आएगा।\n\n💡 Hint: पौधों की कोशिका (Plant Cell) में एक कठोर "कोशिका भित्ति" (Cell Wall) होती है जो जंतु कोशिका में नहीं होती।\n\nक्या आप माइटोकॉन्ड्रिया के बारे में और गहराई से पढ़ना चाहते हैं?', yt: 'https://www.youtube.com/watch?v=URUJD5NEXC8');
      
      return _t('general', '$name, यह बहुत ही बेहतरीन सवाल है! विस्तृत जानकारी प्राप्त करने के लिए इसे छोटे भागों में समझना सही रहेगा।\n\n📌 किसी भी विषय को समझने के लिए:\n1. सबसे पहले उसकी मूल परिभाषा को समझें।\n2. महत्वपूर्ण शब्दों (Key Terms) पर ध्यान दें।\n3. असल जिंदगी (Real-world) के उदाहरणों से जोड़ें।\n\n💡 टिप: जो भी आपने समझा है, उसे अपनी भाषा में एक कागज़ पर लिखने (Active Recall) से याददाश्त 40% तक बढ़ जाती है।\n\nकृपया मुझे बताएं कि आप विज्ञान (Science), गणित (Maths) या इतिहास (History) में से कौन सा विषय पढ़ रहे हैं?', yt: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    }

    // ── NATIVE SCRIPTS ──
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(query) || lang.startsWith('kn')) {
      if (q.contains('ಬೆಳಕು') || q.contains('ದ್ಯುತಿಸಂಶ್ಲೇಷಣೆ')) return _t('photosynthesis', '$name, ದ್ಯುತಿಸಂಶ್ಲೇಷಣೆ (Photosynthesis) ಸಸ್ಯಗಳು ಆಹಾರ ತಯಾರಿಸುವ ಪ್ರಕ್ರಿಯೆ.\n\nಸಮೀಕರಣ: 6CO₂ + 6H₂O + ಬೆಳಕು → C₆H₁₂O₆ + 6O₂\n\n💡 Hint: ಇದು ಕ್ಲೋರೊಪ್ಲಾಸ್ಟ್‌ನಲ್ಲಿರುವ ಕ್ಲೋರೊಫಿಲ್ ಮೂಲಕ ನಡೆಯುತ್ತದೆ.', yt: 'https://www.youtube.com/watch?v=UPBMG5EYydo');
      if (q.contains('ಕೋಶ') || q.contains('ಜೀವಕೋಶ')) return _t('cell', '$name, ಜೀವಕೋಶವು (Cell) ಜೀವಿಯ ಮೂಲ ಘಟಕ.\n\n• ನ್ಯೂಕ್ಲಿಯಸ್ (Nucleus): ಜೀವಕೋಶದ ಮಿದುಳು.\n• ಮೈಟೊಕಾಂಡ್ರಿಯಾ: ಶಕ್ತಿ ಉತ್ಪಾದನಾ ಕೇಂದ್ರ (Powerhouse).\n\n💡 Hint: ಸಸ್ಯ ಜೀವಕೋಶದಲ್ಲಿ ಕೋಶ ಭಿತ್ತಿ (Cell Wall) ಇರುತ್ತದೆ.', yt: 'https://www.youtube.com/watch?v=URUJD5NEXC8');
      return _t('kannada_general', '$name, ಇದು ಅದ್ಭುತ ಪ್ರಶ್ನೆ! ವಿಷಯವನ್ನು ಚೆನ್ನಾಗಿ ಅರ್ಥಮಾಡಿಕೊಳ್ಳಲು ಅದರ ಮೂಲಭೂತ ಅಂಶಗಳನ್ನು ಗಮನಿಸಿ.\n\n💡 Hint: ಪ್ರತಿದಿನ ಸ್ವಲ್ಪ ಸಮಯ ಅಧ್ಯಯನ ಮಾಡುವುದು ನೆನಪಿನ ಶಕ್ತಿಯನ್ನು ಹೆಚ್ಚಿಸುತ್ತದೆ. ಬೇರೆ ಏನಾದರೂ ಕಲಿಯಬೇಕೆ?', yt: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    }
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(query) || lang.startsWith('ta')) {
      if (q.contains('ஒளி') || q.contains('ஒளிச்சேர்க்கை')) return _t('photosynthesis', '$name, ஒளிச்சேர்க்கை (Photosynthesis) என்பது தாவரங்கள் உணவு தயாரிக்கும் முறை.\n\nசமன்பாடு: 6CO₂ + 6H₂O + ஒளி → C₆H₁₂O₆ + 6O₂\n\n💡 Hint: இது பச்சையத்தில் (Chlorophyll) நடைபெறுகிறது.', yt: 'https://www.youtube.com/watch?v=UPBMG5EYydo');
      if (q.contains('செல்')) return _t('cell', '$name, செல் (Cell) என்பது உயிரினங்களின் அடிப்படை அலகு.\n\n• உட்கரு (Nucleus): செல்லின் மூளை.\n• மைட்டோகாண்ட்ரியா: ஆற்றல் மையம் (Powerhouse).\n\n💡 Hint: தாவர செல்லில் செல் சுவர் (Cell Wall) உள்ளது.', yt: 'https://www.youtube.com/watch?v=URUJD5NEXC8');
      return _t('tamil_general', '$name, அருமையான கேள்வி! ஒரு கருத்தை நன்கு புரிந்து கொள்ள அதன் அடிப்படைகளை கவனிக்கவும்.\n\n💡 Hint: தினமும் படிப்பது ஞாபக சக்தியை அதிகரிக்கும். வேறு என்ன கற்க விரும்புகிறீர்கள்?', yt: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    }
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(query) || lang.startsWith('te')) {
      if (q.contains('కాంతి') || q.contains('కిరణజన్య')) return _t('photosynthesis', '$name, కిరణజన్య సంయోగక్రియ (Photosynthesis) ద్వారా మొక్కలు ఆహారం తయారు చేసుకుంటాయి.\n\nసమీకరణం: 6CO₂ + 6H₂O + కాంతి → C₆H₁₂O₆ + 6O₂\n\n💡 Hint: ఇది క్లోరోఫిల్ సహాయంతో జరుగుతుంది.', yt: 'https://www.youtube.com/watch?v=UPBMG5EYydo');
      if (q.contains('కణం')) return _t('cell', '$name, కణం (Cell) జీవుల ప్రాథమిక యూనిట్.\n\n• కేంద్రకం (Nucleus): కణం మెదడు.\n• మైటోకాండ్రియా: శక్తి కేంద్రం (Powerhouse).\n\n💡 Hint: వృక్ష కణంలో కణ కవచం (Cell Wall) ఉంటుంది.', yt: 'https://www.youtube.com/watch?v=URUJD5NEXC8');
      return _t('telugu_general', '$name, మంచి ప్రశ్న! ఏదైనా విషయాన్ని బాగా అర్థం చేసుకోవడానికి దాని ప్రాథమిక సూత్రాలను గమనించండి.\n\n💡 Hint: ప్రతిరోజు చదవడం జ్ఞాపకశక్తిని పెంచుతుంది. ఇంకేమైనా నేర్చుకోవాలనుకుంటున్నారా?', yt: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    }
    if (RegExp(r'[\u0900-\u097F]').hasMatch(query) || lang.startsWith('hi')) {
      if (q.contains('त्रिकोणमिति')) return _t('trigonometry', '$name, त्रिकोणमिति (Trigonometry) में हम समकोण त्रिभुज का अध्ययन करते हैं।\n\n📌 मुख्य सूत्र:\n• Sin θ = लंब / कर्ण\n• Cos θ = आधार / कर्ण\n• Tan θ = लंब / आधार\n\n💡 Hint: पाइथागोरस प्रमेय (a² + b² = c²) भी यहाँ बहुत काम आती है।', yt: 'https://www.youtube.com/watch?v=PUB0TaZ7bhA');
      if (q.contains('प्रकाश') || q.contains('संश्लेषण')) return _t('photosynthesis', '$name, प्रकाश संश्लेषण पौधों के लिए भोजन बनाने की प्रक्रिया है।\n\nसमीकरण: 6CO₂ + 6H₂O + प्रकाश → C₆H₁₂O₆ + 6O₂\n\n💡 Hint: यह प्रक्रिया क्लोरोप्लास्ट में मौजूद क्लोरोफिल के कारण होती है। ऑक्सीजन इसका बाई-प्रोडक्ट है।', yt: 'https://www.youtube.com/watch?v=UPBMG5EYydo');
      if (q.contains('कोशिका')) return _t('cell', '$name, कोशिका जीवन की मूलभूत इकाई है।\n\n• केंद्रक (Nucleus): कोशिका का नियंत्रण कक्ष (DNA)।\n• माइटोकॉन्ड्रिया: कोशिका का पावरहाउस जहाँ ATP ऊर्जा बनती है।\n\n💡 Hint: पादप कोशिका में कोशिका भित्ति (Cell Wall) होती है, जंतु में नहीं।', yt: 'https://www.youtube.com/watch?v=URUJD5NEXC8');
      return _t('hindi_general', '$name, यह बहुत अच्छा सवाल है! यह एक उन्नत विषय लगता है।\n\n💡 Hint: किसी भी विषय को गहराई से समझने के लिए उसके बुनियादी सिद्धांतों (Fundamentals) पर ध्यान दें।\n\nक्या आप मुझे इस विषय से जुड़ा कोई विशिष्ट शब्द (Specific concept) बता सकते हैं?', yt: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    }

    // ── CONVERSATION CONTINUITY ──
    if (_lastTopic.isNotEmpty && _isFollowUp(q)) return _continue(q, name);

    // ── ENGLISH TOPICS WITH HINTS ──
    if (q.contains('trigonometry') || q.contains('sin') || q.contains('cos') || q.contains('tan')) return _t('trigonometry', '📐 TRIGONOMETRY\n\n$name, trigonometry studies relationships between angles and sides of triangles.\n\n🔑 The Three Main Ratios (SOH CAH TOA):\n• Sine (sin θ) = Opposite ÷ Hypotenuse\n• Cosine (cos θ) = Adjacent ÷ Hypotenuse\n• Tangent (tan θ) = Opposite ÷ Adjacent\n\n📝 Important Values:\n• sin 0°=0, sin 30°=0.5, sin 45°=1/√2, sin 60°=√3/2, sin 90°=1\n• cos 0°=1, cos 30°=√3/2, cos 45°=1/√2, cos 60°=0.5, cos 90°=0\n\n⚡ Key Identity: sin²θ + cos²θ = 1\n\n💡 Memory Trick: "Some Old Horses Can Always Hear Their Owner Approaching" → SOH CAH TOA\n\nWant me to solve a problem step by step?', yt: 'https://www.youtube.com/watch?v=PUB0TaZ7bhA');
    if (q.contains('photosynthesis') || q.contains('chlorophyll') || q.contains('plant')) return _t('photosynthesis', '🌿 PHOTOSYNTHESIS\n\n$name, photosynthesis is how green plants make their own food using sunlight!\n\n🔑 Chemical Equation:\n6CO₂ + 6H₂O + Sunlight → C₆H₁₂O₆ + 6O₂\n(Carbon dioxide + Water + Light → Glucose + Oxygen)\n\n📝 Where It Happens:\n• Organ: Leaves\n• Organelle: Chloroplasts\n• Pigment: Chlorophyll (absorbs red & blue light, reflects green)\n\n⚡ Two Stages:\n1. Light Reactions (thylakoids) — water split, O₂ released, ATP made\n2. Calvin Cycle (stroma) — CO₂ fixed into glucose\n\n📌 Key Facts:\n• Plants produce the oxygen we breathe\n• Rate increases with light intensity (up to a point)\n• A single leaf has millions of chloroplasts\n\n💡 Think of it as the opposite of respiration!\n\nWhat happens if we increase light intensity?', yt: 'https://www.youtube.com/watch?v=UPBMG5EYydo');
    if (q.contains('newton') || q.contains('gravity') || q.contains('force') || q.contains('motion')) return _t('newton', '🍎 NEWTON\'S LAWS OF MOTION\n\n$name, these three laws form the foundation of physics!\n\n🔑 First Law (Inertia):\nObjects stay at rest or in constant motion unless a force acts on them.\n• Example: A ball stays still until kicked\n\n🔑 Second Law (F = ma):\nForce = Mass × Acceleration. More mass needs more force.\n• Example: Pushing an empty vs loaded cart\n• Unit: Newton (N) = kg × m/s²\n\n🔑 Third Law (Action-Reaction):\nEvery action has an equal and opposite reaction.\n• Example: Walking — foot pushes ground back, ground pushes you forward\n• Rockets: hot gases push down, rocket goes up!\n\n📌 Gravity: g = 9.8 m/s² (Earth), 1.6 m/s² (Moon)\nWeight = mass × g\n\n💡 Fun Fact: Newton was only 23 when he developed these!\n\nWhich law would you like me to explain with more examples?', yt: 'https://www.youtube.com/watch?v=kKKM8Y-u7ds');
    if (q.contains('cell') || q.contains('mitochondria') || q.contains('nucleus')) return _t('cell', '🔬 THE CELL\n\n$name, the cell is the basic unit of life! Discovered by Robert Hooke in 1665.\n\n🔑 Key Organelles:\n• Nucleus — "Brain" of cell, contains DNA\n• Mitochondria — "Powerhouse," produces ATP energy\n• Cell Membrane — Controls what enters/exits\n• ER — Rough (makes proteins), Smooth (makes lipids)\n• Golgi — "Post office," packages proteins\n• Ribosomes — Build proteins from amino acids\n• Lysosomes — "Cleanup crew," digests waste\n\n📝 Plant vs Animal Cells:\n• Plant ONLY: Cell wall, Chloroplasts, Large vacuole\n• Both have: Nucleus, Mitochondria, ER, Golgi\n\n💡 Memory: "Mighty Mitochondria Make ATP"\n\nWant to learn about cell division?', yt: 'https://www.youtube.com/watch?v=URUJD5NEXC8');
    if (q.contains('algebra') || q.contains('equation') || q.contains('quadratic')) return _t('algebra', '🔢 ALGEBRA & QUADRATIC EQUATIONS\n\n$name, here\'s a complete guide!\n\n🔑 Quadratic: ax² + bx + c = 0\nFormula: x = (-b ± √(b²-4ac)) / 2a\n\n📝 The Discriminant (D = b²-4ac):\n• D > 0 → Two roots\n• D = 0 → One root\n• D < 0 → No real roots\n\n⚡ Solved Example:\nx² - 5x + 6 = 0\na=1, b=-5, c=6\nD = 25-24 = 1\nx = (5±1)/2 → x=3 or x=2\nVerify: 9-15+6=0 ✓\n\n📌 Properties:\n• Sum of roots = -b/a\n• Product of roots = c/a\n\n💡 Shortcut: Try factoring! (x-2)(x-3)=0\n\nWant a practice problem?', yt: 'https://www.youtube.com/watch?v=IlNAJl36-10');
    if (q.contains('atom') || q.contains('element') || q.contains('periodic')) return _t('atom', '⚛️ ATOMS & PERIODIC TABLE\n\n$name, atoms are the building blocks of matter!\n\n🔑 Structure:\n• Protons (+) — In nucleus, determines element\n• Neutrons (0) — In nucleus, adds mass\n• Electrons (-) — Orbit in shells\n\n📝 Key Concepts:\n• Atomic Number = Protons (Carbon = 6)\n• Mass Number = Protons + Neutrons\n• Neutral atom: protons = electrons\n\n⚡ Electron Shells (2, 8, 8):\n• 1st shell: max 2\n• 2nd shell: max 8\n• 3rd shell: max 8\n\n📌 Periodic Table:\n• Rows (Periods) = electron shells\n• Columns (Groups) = valence electrons\n• Group 1: Alkali metals (reactive)\n• Group 18: Noble gases (stable)\n\n💡 First 10: H He Li Be B C N O F Ne\n\nWhich element interests you?', yt: 'https://www.youtube.com/watch?v=rz4Dd1I_fX0');
    if (q.contains('what') || q.contains('how') || q.contains('why') || q.contains('explain') || q.contains('tell') || q.contains('mean') || q.contains('define')) return _t('general', '$name, that\'s a wonderful question! Let me break it down for you.\n\n📝 To understand any concept well, follow these steps:\n1. Understand the basic definition first\n2. Identify the key terms and their meanings\n3. Look for real-world examples\n4. Connect it to what you already know\n5. Try to explain it in your own words\n\n💡 Study Tip: The best learners use active recall — close the book and try to write what you remember. This boosts retention by 40%!\n\n📌 Tell me which subject or chapter this relates to and I\'ll give you a detailed, step-by-step explanation with examples and formulas!', yt: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    if (_lastTopic.isNotEmpty) return _continue(q, name);
    return null;
  }

  bool _isHinglish(String q) {
    final markers = ['mujhe', 'batao', 'sikhao', 'sikhade', 'kya hai', 'samjhao', 'ke baare', 'ke barein', 'bataiye', 'padhai', 'padhao', 'kaise', 'kyun', 'matlab', 'mein', 'hota', 'karo', 'sikha'];
    return markers.any((m) => q.contains(m));
  }

  _FB _t(String topic, String reply, {String? yt}) { _lastTopic = topic; return _FB(reply, youtubeUrl: yt); }

  bool _isFollowUp(String q) {
    final words = ['yes', 'no', 'ok', 'sure', 'tell me', 'explain', 'more', 'haan', 'nahi', 'please', 'go on', 'continue', 'next', 'why', 'how', 'what about', 'thanks', 'haa', 'aur'];
    return words.any((w) => q.contains(w)) || q.split(' ').length <= 5;
  }

  _FB? _continue(String q, String name) {
    final r = {
      'trigonometry': '$name, great! sin45° = 1/√2 ≈ 0.707. The unit circle maps all trig values. At 0° sin=0, at 90° sin=1.\n\n💡 Remember: All Students Take Calculus — tells which ratios are positive in each quadrant!',
      'photosynthesis': 'The leaf, $name! Specifically chloroplasts in mesophyll cells. Light reactions happen in thylakoids, dark reactions in stroma.\n\n💡 Interesting: A single leaf has millions of chloroplasts!',
      'newton': 'Great example thinking, $name! Walking: your foot pushes ground backward (action), ground pushes you forward (reaction). Rockets work the same way!\n\n💡 Fun fact: Newton was only 23 when he developed calculus!',
      'cell': 'The Golgi apparatus packages proteins, $name! Think of it as the cell\'s post office.\n\n💡 Memory trick: Golgi = Go deliver!',
      'algebra': '$name, for x²-5x+6=0: factors are (x-2)(x-3)=0, so x=2 or x=3! Check: 4-10+6=0 ✓\n\n💡 Shortcut: sum of roots = -b/a = 5, product = c/a = 6',
      'hindi_general': '$name, बहुत अच्छा! इस विषय के मुख्य बिंदु नोट करें। रोज 15 मिनट revision करें!\n\n💡 टिप: Pomodoro तकनीक से पढ़ें — 25 मिनट पढ़ो, 5 मिनट ब्रेक!',
    };
    return _FB(r[_lastTopic] ?? 'Great follow-up, $name! Let me know which specific part you want me to explain.\n\n💡 Tip: Writing down what you learned helps memory retention by 40%!', youtubeUrl: 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(q)}');
  }

  void _notifyNewMessage() { onNewMessage?.call(); }
}

class _FB { final String reply; final String? youtubeUrl; _FB(this.reply, {this.youtubeUrl}); }
