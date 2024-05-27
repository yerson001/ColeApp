import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import 'dart:io';
import 'package:soundpool/soundpool.dart';
import 'package:http/http.dart' as http;

class QRScannerPage extends StatefulWidget {
  /// QRScannerPage
  final String apiResponse;
  const QRScannerPage({Key? key, required this.apiResponse}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey();
  Map<String, bool> scannedCodes = {};
  String _typeAssistance = 'entrance';

  final ValueNotifier<Barcode?> _result = ValueNotifier<Barcode?>(null);
  final ValueNotifier<String> _username = ValueNotifier<String>('');
  final ValueNotifier<String> _token = ValueNotifier<String>('');
  final ValueNotifier<String> _slug = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    // Analiza el JSON y extrae el nombre de usuario
    final Map<String, dynamic> responseData = jsonDecode(widget.apiResponse);
    _username.value = responseData['user']['username'];
    _token.value = responseData['token'];
    _slug.value = responseData['school']['slug'];
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

return Scaffold(
  appBar: AppBar(
    title: const Text("Asistencia"),
    actions: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 5),
            ValueListenableBuilder<String>(
              valueListenable: _username,
              builder: (context, value, child) {
                return Text(value);
              },
            ),
          ],
        ),
      ),
    ],
  ),
  body: GestureDetector(
    onTap: () {
      FocusScope.of(context).requestFocus(FocusNode()); // Oculta el teclado cuando se toca en cualquier parte de la pantalla
    },
    child: SingleChildScrollView(
      child: Container(
        color: Colors.white,
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Token: ${_token.value}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              'Slug: ${_slug.value}',
              style: const TextStyle(fontSize: 10),
            ),
                            TurnoSelector(
                  onTurnoSelected: (value) {
                    setState(() {
                      _typeAssistance = value == 'Entrada' ? 'entrance' : 'exit';
                    });
                  },
                ),
            const SizedBox(height: 20),
            //SearchField(), 
            
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: width * 0.7,
                height: width * 0.7,
                child: QRView(
                  key: qrKey,
                  onPermissionSet: (ctrl, permission) {
                    log('onPermissionSet $permission');
                    if (!permission) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No Permission')),
                      );
                    }
                  },
                  onQRViewCreated: (QRViewController ctrl) {
                    controller = ctrl;
                    ctrl.scannedDataStream.listen((scanData) {
                      _result.value = scanData;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 100), // Espacio para evitar que el teclado cubra los datos del código QR
            
            
          ValueListenableBuilder(
  valueListenable: _result,
  builder: (BuildContext context, Barcode? result, _) {
    String decryptedData = result != null
        ? decrypt(result.code!)
        : 'Enfoca el Qr dentro del recuadro';

    if (decryptedData != 'Enfoca el Qr dentro del recuadro') {
      List<String> values = decryptedData.split('\$');
      if (values.length == 5) {
        // Verifica si el código QR ya está en el diccionario
        bool isDuplicate = scannedCodes.containsKey(decryptedData);

        if (!isDuplicate) {
          // Si el código QR es nuevo, reproduce el sonido y almacena el código en el diccionario
          _soundButton();
          scannedCodes[decryptedData] =
              true; // Almacena el código QR escaneado en el diccionario

          // Construye el cuerpo de la solicitud HTTP
          Map<String, dynamic> body = {
            "dni": values[2], // Se asume que el DNI está en la posición 2
            "type_assistance": _typeAssistance
          };

          // Realiza la solicitud HTTP
          http.post(
            Uri.parse('https://colecheck.com/api/register_assistance'),
            headers: {
              'Authorization': 'token ${_token.value}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          ).then((response) {
            // Maneja la respuesta de la API aquí
            if (response.statusCode == 200) {
              // Éxito
              print('Solicitud exitosa*******************************************');
            } else {
              // Error
              print('Error: ${response.statusCode}');
            }
          }).catchError((error) {
            // Maneja los errores de la solicitud HTTP aquí
            print('Error: $error');
          });
        }

        // Muestra los datos del código QR
        return _buildQRData(values);
      }
    }

    return Text(decryptedData);
  },
),




          ],
        ),
      ),
    ),
  ),


);


  }

  String decrypt(String encryptedText, [int key = 3]) {
    const listOfChars = [
      'á',
      'Á',
      'é',
      'É',
      'í',
      'Í',
      'ó',
      'Ó',
      'ú',
      'Ú',
      'ñ',
      'Ñ'
    ];
    String decryptedText = '';

    for (int i = 0; i < encryptedText.length; i++) {
      String char = encryptedText[i];
      if (listOfChars.contains(char)) {
        decryptedText += char;
      } else if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        int start = RegExp(r'[a-z]').hasMatch(char)
            ? 'a'.codeUnitAt(0)
            : 'A'.codeUnitAt(0);
        decryptedText += String.fromCharCode(
            (char.codeUnitAt(0) - start - key + 26) % 26 + start);
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        decryptedText += String.fromCharCode(
            (char.codeUnitAt(0) - '0'.codeUnitAt(0) - key + 10) % 10 +
                '0'.codeUnitAt(0));
      } else {
        decryptedText += char;
      }
    }

    return decryptedText;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _soundButton() async {
    Soundpool pool = Soundpool(streamType: StreamType.notification);

    int soundId =
        await rootBundle.load("assets/pid.wav").then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId);
  }
}

Widget _buildQRData(List<String> values) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(width: 30), // Margen izquierdo
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Nombre: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text: '${values[0]}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Apellido: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text: '${values[1]}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'DNI: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text: '${values[2]}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Grado: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text: '${values[3]}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Sección: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black),
                  ),
                  TextSpan(
                    text: '${values[4]}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 20), // Espacio entre los datos y el avatar
      const Padding(
        padding: EdgeInsets.only(right: 30), // Margen derecho
        child: CircleAvatar(
          child: Icon(Icons.account_circle, size: 60), // Icono de avatar
          radius: 40, // Tamaño del avatar
        ),
      ),
    ],
  );
}


class TurnoSelector extends StatefulWidget {
  final Function(String) onTurnoSelected;

  TurnoSelector({required this.onTurnoSelected});

  @override
  _TurnoSelectorState createState() => _TurnoSelectorState();
}

class _TurnoSelectorState extends State<TurnoSelector> {
  String _selectedTurno = 'Entrada';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elija su turno',
          style: TextStyle(fontSize: 12), // Tamaño del texto del label
        ),
        const SizedBox(height: 5), // Espacio entre el texto y el dropdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _selectedTurno,
              isExpanded: true,
              items: ['Entrada', 'Salida'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 12), // Cambia el tamaño del texto a 12
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTurno = value!;
                  widget.onTurnoSelected(value); // Llama a la función de devolución de llamada
                });
              },
              dropdownMaxHeight: 100, // Ajusta la altura máxima del dropdown
              dropdownWidth: 120, // Ajusta el ancho del dropdown
              dropdownPadding: const EdgeInsets.symmetric(horizontal: 10),
              dropdownDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              dropdownElevation: 8,
              scrollbarRadius: const Radius.circular(10),
              scrollbarThickness: 6,
              scrollbarAlwaysShow: true,
            ),
          ),
        ),
      ],
    );
  }
}