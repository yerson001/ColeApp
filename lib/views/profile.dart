import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:coleapp/models/users.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:provider/provider.dart';

class Profile extends StatelessWidget {
  final Users? profile;
  const Profile({Key? key, this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 5),
                Text(profile!.usrName),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primera fila
                Row(
                  children: [
                    // Primera columna
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Elija su turno",
                          border: OutlineInputBorder(),
                        ),
                        items: ['Entrada', 'Salida']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(fontSize: 12), // Cambia el tamaño del texto a 16
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          // Acción al seleccionar un valor del dropdown
                        },
                      ),
                    ),
                    SizedBox(width: 20), // Espacio entre las columnas
                    // Segunda columna
                    ElevatedButton(
                      onPressed: () {
                        // Acción al presionar el botón "Finalizar"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Color de fondo rojo
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Modifica el redondeado del botón
                        ),
                      ),
                      child: Text(
                        "Finalizar",
                        style: TextStyle(color: Colors.white), // Cambia el color del texto a blanco
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Espacio entre las filas
                // Segunda fila
                Row(
                  children: [
                    // Primera columna
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Buscar alumno",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 20), // Espacio entre las columnas
                    // Segunda columna
                    ElevatedButton(
                      onPressed: () {
                        // Acción al presionar el botón "Buscar"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Color de fondo verde
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Modifica el redondeado del botón
                        ),
                      ),
                      child: Text(
                        "Buscar",
                        style: TextStyle(color: Colors.white), // Cambia el color del texto a blanco
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20), // Espacio entre las filas
                // Tercera fila
                Row(
                  children: [
                    // Primera columna
                    Expanded(
                      child: Column(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const QRScannerPage(),
                                ),
                              );
                            },
                            icon: Icon(Icons.qr_code),
                            iconSize: 50,
                          ),
                          SizedBox(height: 10), // Espacio entre el icono y el siguiente
                          Text("Escanear QR"), // Texto debajo del icono
                        ],
                      ),
                    ),
                    SizedBox(width: 20), // Espacio entre las columnas
                    // Segunda columna
                    Expanded(
                      child: Column(
                        children: [
                          IconButton(
                            onPressed: () {
                              scanningDialog(context);
                              Provider.of<NFCNotifier>(context, listen: false)
                                  .startNFCOperation(nfcOperation: NFCOperation.read);
                            },
                            icon: Icon(Icons.nfc),
                            iconSize: 50, // Tamaño del icono
                          ),

                          SizedBox(height: 10), // Espacio entre el icono y el siguiente
                          Text("Escanear NFC"), // Texto debajo del icono
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void scanningDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const AlertDialog(
        title: Text('Escaneando Tarjeta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Acerque la Tejeta NFC...'),
          ],
        ),
      );
    },
  );
}
/// QRScannerPage
class QRScannerPage extends StatefulWidget {
  /// QRScannerPage
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey();

  final ValueNotifier<Barcode?> _result = ValueNotifier<Barcode?>(null);

  // In order to get hot reload to work we need to pause the camera
  // if the platform
  // is android, or resume the camera if the platform is iOS.
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
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              overlay: QrScannerOverlayShape(
                cutOutSize: width * 0.7,
              ),
              key: qrKey,
              onPermissionSet: (ctrl, permission) {
                log('onPermissionSet $permission');
                if (!permission) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('no Permission')),
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
          Expanded(
            child: Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: _result,
                  builder: (BuildContext context, Barcode? result, _) {
                    return Text(
                      result != null
                          ? '''
Barcode Type: ${describeEnum(result.format)} \nData: ${result.code}'''
                          : 'Scan a code',
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder(
                      future: controller?.getFlashStatus(),
                      builder: (context, snapshot) {
                        return InkWell(
                          onTap: () async {
                            setState(() async {
                              await controller?.toggleFlash();
                            });
                          },
                          child: Icon(
                            snapshot.data ?? true
                                ? Icons.flash_off
                                : Icons.flash_on,
                            size: height * 0.05,
                          ),
                        );
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}


class NFCNotifier extends ChangeNotifier {
  bool _isProcessing = false;
  String _message = "";

  bool get isProcessing => _isProcessing;

  String get message => _message;

  Future<void> startNFCOperation({
    required NFCOperation nfcOperation,
    String dataType = "",
  }) async {
    try {
      _isProcessing = true;
      notifyListeners();

      bool isAvail = await NfcManager.instance.isAvailable();

      if (isAvail) {
        if (nfcOperation == NFCOperation.read) {
          _message = "Escaneando";
        } else if (nfcOperation == NFCOperation.write) {
          _message = "Escribiendo en la Tarjeta";
        }

        notifyListeners();

        NfcManager.instance.startSession(onDiscovered: (NfcTag nfcTag) async {
          if (nfcOperation == NFCOperation.read) {
            _readFromTag(tag: nfcTag);
          } else if (nfcOperation == NFCOperation.write) {
            _writeToTag(nfcTag: nfcTag, dataType: dataType);
            _message = "COMPLETADO";
          }

          _isProcessing = false;
          notifyListeners();
          await NfcManager.instance.stopSession();
        }, onError: (e) async {
          _isProcessing = false;
          _message = e.toString();
          notifyListeners();
        });
      } else {
        _isProcessing = false;
        _message = "Por favor, habilita NFC desde la configuración";
        notifyListeners();
      }
    } catch (e) {
      _isProcessing = false;
      _message = e.toString();
      notifyListeners();
    }
  }

  Future<void> _readFromTag({required NfcTag tag}) async {
    Map<String, dynamic> nfcData = {
      'nfca': tag.data['nfca'],
      'mifareultralight': tag.data['mifareultralight'],
      'ndef': tag.data['ndef']
    };

    String? decodedText;
    if (nfcData.containsKey('ndef')) {
      List<int> payload =
      nfcData['ndef']['cachedMessage']?['records']?[0]['payload'];
      decodedText = String.fromCharCodes(payload);
    }

    _message = decodedText ?? "No Data Found";
  }

  Future<void> _writeToTag(
      {required NfcTag nfcTag, required String dataType}) async {
    NdefMessage message = _createNdefMessage(dataType: dataType);
    await Ndef.from(nfcTag)?.write(message);
  }

  NdefMessage _createNdefMessage({required String dataType}) {
    switch (dataType) {
      case 'PLAIN_TEXT':
        {
          String randomText = "hello como estas";
          Uint8List textBytes = utf8.encode(randomText);
          return NdefMessage([
            NdefRecord.createMime(
              'text/plain',
              textBytes,
            )
          ]);
        }
      default:
        return const NdefMessage([]);
    }
  }
}

enum NFCOperation { read, write }