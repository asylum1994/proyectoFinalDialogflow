import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = 'presiona el boton para empezar a hablar';

  bool audioCompleto = false;

  /// flutter text to speech
  FlutterTts flutterTts = FlutterTts();
  final TextEditingController textEditingController = TextEditingController();

  speak() async {
    await flutterTts.setLanguage("es-BO");
    await flutterTts.setPitch(1); // 0.5 to 1.5
    await flutterTts.speak(_lastWords);
    // bool isCompleted = await flutterTts.awaitSpeakCompletion(true);
  }

  //////////////////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bienvenido"),
      ),
      body: principal(),
    );
  }

  Widget principal() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          buildContainerText(),
          const SizedBox(height: 30),
          buildElevatedButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget buildElevatedButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _speechToText.isNotListening
                  ? _startListening()
                  : _stopListening();
            });
          },
          child: Icon(
            _speechToText.isListening ? Icons.mic_off : Icons.mic,
            size: 35,
          ),
          style: ElevatedButton.styleFrom(
              backgroundColor:
                  _speechToText.isListening ? Colors.red : Colors.green,
              minimumSize: const Size(90, 90),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50))),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              speak();
            });
          },
          child: Icon(
            Icons.play_arrow,
            size: 35,
          ),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(90, 90),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50))),
        ),
      ],
    );
  }

  /* _speechToText.isListening
            ? '$_lastWords'
            : _speechEnabled
                ? 'Tap the microphone to start listening...'
                : 'Speech not available',*/
  Widget buildContainerText() {
    return Container(
      child: Center(child: Text(_lastWords)),
      height: MediaQuery.of(context).size.height * 0.65,
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(color: Colors.black12),
    );
  }
}
