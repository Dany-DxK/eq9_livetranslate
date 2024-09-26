import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:translator/translator.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  String _translatedText = "";
  String _selectedLanguage = "en"; // Idioma por defecto
  final translator = GoogleTranslator(); // Inicializar traductor

  @override
  void initState() {
    super.initState();
    initSpeech();
    requestOverlayPermission(); // Solicitar permiso para overlay
  }

  // Solicitar permiso para mostrar sobre otras aplicaciones
  Future<void> requestOverlayPermission() async {
    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  // Mostrar ventana flotante con widget personalizado
  void showFloatingWindow() async {
    await FlutterOverlayWindow.showOverlay(
      alignment: OverlayAlignment.center,
      height: 200,
      width: 300,
      enableDrag: true,
      overlayContent: _translatedText, // Mostrar texto traducido
    );
  }

  // Inicializa el reconocimiento de voz
  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  // Comenzar a escuchar
  void _startListening() async {
    if (!_speechToText.isListening) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _confidenceLevel = 0;
      });
    }
  }

  // Detener escucha
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  // Obtener resultado del reconocimiento de voz y traducir
  void _onSpeechResult(result) async {
    setState(() {
      _wordsSpoken = "${result.recognizedWords}";
      _confidenceLevel = result.confidence;
    });
    await _translateText(_wordsSpoken, _selectedLanguage);
    showFloatingWindow(); // Mostrar ventana flotante con el texto traducido
  }

  // Función para traducir el texto usando Google Translate
  Future<void> _translateText(String text, String targetLang) async {
    try {
      var translation = await translator.translate(text, to: targetLang);
      setState(() {
        _translatedText = translation.text;
      });
    } catch (e) {
      print("Error al traducir: $e");
    }
  }

  // Selección de idioma
  //String _selectedLanguage = 'en'; // Idioma predeterminado (ingles)
  List<String> _languages = ['es', 'en', 'fr', 'de', 'it']; // Idiomas disponibles

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          'Prueba de Sonido',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _selectedLanguage,
            onChanged: (String? newValue) {
              setState(() {
                _selectedLanguage = newValue!;
              });
            },
            items: _languages.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _speechToText.isListening
                          ? "Escuchando..."
                          : _speechEnabled
                          ? "Presiona el micrófono para comenzar a hablar..."
                          : "Discurso no disponible",
                      style: TextStyle(fontSize: 20.0),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Texto hablado: $_wordsSpoken",
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Texto traducido: $_translatedText",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isListening ? _stopListening : _startListening,
        tooltip: 'Escuchar',
        child: Icon(
          _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
