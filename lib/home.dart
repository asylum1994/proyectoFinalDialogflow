import 'dart:math';

import 'package:dialogflow_grpc/generated/google/cloud/dialogflow/v2/intent.pb.dart';
import 'package:dialogflow_grpc/generated/google/protobuf/struct.pb.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

import 'package:dialogflow_grpc/v2beta1.dart';
import 'package:dialogflow_grpc/generated/google/cloud/dialogflow/v2beta1/session.pb.dart';
import 'package:dialogflow_grpc/dialogflow_auth.dart';
import 'package:interface_de_voz/reserva.dart';
import 'package:interface_de_voz/moto.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Widget> listaReservas = [];
  List<String> datoCliente = [];
  List<Moto> datoMoto = [];

  String nMoto = "";
  String nColor = "";
  String nCliente = "";
  String ncinit = "";
  String nPago = "";

  DialogflowGrpcV2Beta1? dialogflow;
  List<String> dataList = [];
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = 'presiona el boton para empezar a hablar';
  String? _responseDialog;

  /// flutter text to speech
  FlutterTts flutterTts = FlutterTts();
  final TextEditingController textEditingController = TextEditingController();

  //////////////////////////////////////////////
  List<Map<String, dynamic>> listaMoto = [
    {
      'nombre': 'cb160f',
      'color': ['rojo', 'blanco', 'negro'],
    },
    {
      'nombre': 'xblade160',
      'color': ['rojo', 'negro', 'azul'],
    },
    {
      'nombre': 'cb125f twister',
      'color': ['rojo', 'negro', 'blanco'],
    },
    {
      'nombre': 'navi',
      'color': ['rojo', 'negro', 'blanco', 'azul', 'verde'],
    },
    {
      'nombre': 'cg110',
      'color': ['rojo', 'azul'],
    },
    // Puedes agregar más HashMaps según sea necesario
  ];

  List<String> pago = ['QR', 'tigo money', 'tarjeta de credito', 'paypal'];

  /// text to speech
  speak(String texto) async {
    await flutterTts.setLanguage("es-BO");
    await flutterTts.setPitch(1); // 0.5 to 1.5
    await flutterTts.speak(texto);
    // bool isCompleted = await flutterTts.awaitSpeakCompletion(true);
  }

  speakDialogFlow(List<String> lista) async {
    for (var element in lista) {
      await flutterTts.setLanguage("es-BO");
      await flutterTts.setPitch(1); // 0.5 to 1.5
      await flutterTts.speak(element);
      await flutterTts.awaitSpeakCompletion(true);
    }
    // Pausa la ejecución hasta que termine la reproducción actual
    // bool isCompleted = await flutterTts.awaitSpeakCompletion(true);
  }

  //////////////////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    inicioPlugin();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      if (_speechToText.isNotListening) {
        sendIntent(_lastWords);
      }
    });
  }

  /// dialog flow  consumir servicio
  Future<void> inicioPlugin() async {
    final cuentaServicio = ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/reservaMotocicletas.json'))}');
    dialogflow = DialogflowGrpcV2Beta1.viaServiceAccount(cuentaServicio);
  }

  Future<void> sendIntent(text) async {
    DetectIntentResponse? datos =
        await dialogflow?.detectIntent(text, 'es-419');
    // String? textocompleto = datos?.queryResult.fulfillmentText;
    // String? tipoIntent = datos?.queryResult.intent.displayName;
    responseDialogflow(datos);
    dataList = [];
    for (var message in datos!.queryResult!.fulfillmentMessages!) {
      print(message.text.text.first);
      dataList.add(message.text.text.first);
    }
    speakDialogFlow(dataList);
  }

  void responseDialogflow(DetectIntentResponse? data) {
    String? tipoIntent =
        data?.queryResult.intent.displayName; // obtengo el intent
    switch (tipoIntent) {
      case 'confirmacionCliente':
        setState(() {
          listaReservas.add(reserva(nCliente, ncinit, nPago));
          listaReservas.add(SizedBox(
            width: 5,
          ));
        });
        speak(
            "gracias por confirmar sus datos personales , Detalle, nombre: $nCliente , ci o nit : $ncinit, tipo de pago : $nPago, su registro fue exitoso , muchas gracias por su reserva");
        break;
      case 'confirmacionMoto':
        speak(
            "gracias por confirmar los datos de la moto : $nMoto, color $nColor, le gustaria hacer otra reserva ?, si es asi por favor indicar el nombre de la moto que desea reservar");
        datoMoto.add(Moto(nombre: nMoto, color: nColor));
        break;
      case 'nombreMoto':
        String? nameMoto =
            data?.queryResult.ensureParameters().fields['moto']?.stringValue;
        validarMoto(nameMoto!);
        nMoto = nameMoto;
        break;
      case 'colorMoto':
        String? color =
            data?.queryResult.ensureParameters().fields['color']?.stringValue;
        nColor = color!;
        validarColorMoto();
        break;
      case 'nombreCliente':
        Value? person = data?.queryResult.ensureParameters().fields['person'];
        nCliente = person!.structValue.fields['name']!.stringValue;
        print(person!.structValue.fields['name']!.stringValue);
        break;
      case 'ci_nit_cliente':
        String? ci_nit = data?.queryResult
            .ensureParameters()
            .fields['number']
            ?.numberValue
            .toString();
        ncinit = ci_nit!;
        break;
      case 'tipoDePagoCliente':
        String? pago = data?.queryResult
            .ensureParameters()
            .fields['tipoDePago']
            ?.stringValue;
        nPago = pago!;
        validarTipoDePago(pago);
        break;
      case 'quitarItem':
        String? deleteMoto =
            data?.queryResult.ensureParameters().fields['moto']?.stringValue;
        validarQuitarItem(deleteMoto!);
        break;
    }
  }

  void validarQuitarItem(String value) {
    datoMoto.forEach((element) {
      if (element.nombre == value) {
        datoMoto.remove(element);
        speak(
            "la moto ${element.nombre} ha sido quitada de su lista de reservas, me podria confirmar si sus datos estan correctos para poder finalizar la reserva");

        return;
      }
    });
    speak("la moto $value, no se encuentra en su lista de reservas");
  }

  void validarTipoDePago(String tipoPago) {
    if (pago.contains(tipoPago)) {
      speak(
          "has escogido el tipo de pago $tipoPago , Detalle del cliente : nombre: $nCliente, ci o nit : $ncinit, tipo de pago : $tipoPago , me podria confirmar si los datos estan correctos ");
    } else {
      speak(
          "el tipo de pago que escogiste, no existe en las opciones de pago , por favor vuelve a indicarnos el tipo de pago");
    }
  }

  void validarMoto(String nombreMoto) {
    for (var value in listaMoto) {
      if (value['nombre'] == nombreMoto) {
        speak(
            "excelente eleccion has escogido reservar la moto $nombreMoto  , puedes indicar el color de moto que quieres");
        return;
      }
    }
    speak(
        "la moto que indicas, no existe en nuestro catalogo, por favor me podrias volver a indicar la moto que deseas reservar");
  }

  void validarColorMoto() {
    for (var value in listaMoto) {
      if (value['nombre'] == nMoto) {
        List<String> listColor = value['color'];
        if (listColor.contains(nColor)) {
          speak(
              "en hora buena has escogido el color $nColor , Detalle del producto : moto $nMoto , color $nColor, me podrias confirmar si los datos estan correctos");
        } else {
          speak(
              "el color que escogiste, no existe para la moto $nMoto , revisa el catalogo y indicanos el color");
        }
      }
    }
  }

////////////////////////////////////////////////////////////////////////////////
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
          buildContainerReserva(),
          const SizedBox(height: 15),
          buildContainerUser(),
          const SizedBox(height: 15),
          buildCatalogMoto(),
          const SizedBox(height: 15),
          buildElevatedButton(),
          const SizedBox(height: 15),
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
              if (_speechToText.isNotListening) {
                _startListening();
              } else {
                _stopListening();
              }
            });
          },
          child: Icon(
            _speechToText.isListening ? Icons.mic_off : Icons.mic,
            size: 35,
          ),
          style: ElevatedButton.styleFrom(
              backgroundColor:
                  _speechToText.isListening ? Colors.red : Colors.green,
              minimumSize: const Size(70, 70),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50))),
        ),
      ],
    );
  }

  Widget buildContainerReserva() {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            "Reservas",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SingleChildScrollView(
              child: Row(
            children: listaReservas,
          )),
        ],
      ),
      height: MediaQuery.of(context).size.height * 0.30,
      width: MediaQuery.of(context).size.width * 0.95,
      decoration: BoxDecoration(color: Colors.black12),
    );
  }

  Widget buildContainerUser() {
    return Container(
      height: 50,
      width: MediaQuery.of(context).size.width * 0.95,
      decoration: const BoxDecoration(color: Colors.black12),
      child: Center(child: Text(_lastWords)),
    );
  }

  Widget buildCatalogMoto() {
    return Container(
      padding: EdgeInsets.all(7),
      height: MediaQuery.of(context).size.height * 0.35,
      width: MediaQuery.of(context).size.width * 0.95,
      decoration: BoxDecoration(color: Colors.black12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            catalog(
                'moto honda cb160f',
                "https://i.pinimg.com/550x/df/76/9a/df769adaea4111e8f25b4c905f118510.jpg",
                "colores : negro,rojo,blanco",
                "precio reserva :1800Bs"),
            const SizedBox(
              width: 10,
            ),
            catalog(
                'moto honda xblade160',
                "https://www.fpmoto.com/media/wysiwyg/Thomas/Motos/Xblade_azul.jpg",
                "colores : negro,rojo,zul",
                "precio reserva :2000Bs"),
            const SizedBox(
              width: 10,
            ),
            catalog(
                'moto honda cb125f twister',
                "https://pueyrredonmotos.com/honda/wp-content/uploads/2023/09/cb125f-twister-plateada.jpg",
                "colores : negro,rojo,blanco",
                "precio reserva :1300Bs"),
            const SizedBox(
              width: 10,
            ),
            catalog(
                "moto honda navi",
                "https://cdn.motor1.com/images/mgl/eoRNMV/s1/4x3/honda-navi-100.webp",
                "colores : negro,rojo,blanco,verde,azul",
                "precio reserva :1000Bs"),
            const SizedBox(
              width: 10,
            ),
            catalog(
                "moto honda cg110",
                "https://hondabolivia.com/motos/wp-content/uploads/2020/02/PARA-MINIATURA.jpg",
                "colores : azul,rojo",
                "precio reserva :900Bs")
          ],
        ),
      ),
    );
  }

  Widget catalog(String nombre, String image, String color, String precio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          height: MediaQuery.of(context).size.height * 0.25,
          width: 200,
          decoration: const BoxDecoration(color: Colors.red),
          child: Image.network(
            image,
            fit: BoxFit.cover,
          ),
        ),
        Text(
          nombre,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
        Text(
          color,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          precio,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }

  Widget reserva(String nombre, String cinit, String pago) {
    Random random = Random();
    DateTime now = DateTime.now();
    int nroReserva = random.nextInt(90000) + 10000;
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      width: 200,
      decoration: BoxDecoration(color: Colors.white),
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Text(
          "DETALLE : ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("nro de reserva : " + nroReserva.toString()),
        Text("cliente : " + nombre),
        Text("ci o nit : " + cinit),
        Text("tipo de pago : " + pago),
        listMoto(),
        Text("fecha : " +
            now.year.toString() +
            "/" +
            now.month.toString() +
            "/" +
            now.day.toString()),
      ]),
    );
  }

  Widget listMoto() {
    String moto = "";
    String color = "";
    for (var value in datoMoto) {
      // ignore: prefer_interpolation_to_compose_strings
      moto = moto + value.nombre + ", ";
      // ignore: prefer_interpolation_to_compose_strings
      color = color + value.color + ", ";
    }
    return Column(
      children: [
        Text("moto : $moto"),
        Text("color : $color"),
      ],
    );
  }
}
