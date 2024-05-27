import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:coleapp/components/button.dart';
import 'package:coleapp/components/colors.dart';
import 'package:coleapp/components/textfield.dart';
import 'package:coleapp/components/QRScanner.dart';
import 'package:hive/hive.dart';
import 'package:coleapp/models/student.dart'; // Asegúrate de importar el modelo Student

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usrNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isChecked = false;
  bool _isLoggingIn = false;
  bool _isLoginTrue = false;
  String _apiResponse = '';

  @override
  void initState() {
    super.initState();
    _insertSampleData();
  }

  void _insertSampleData() async {
    var box = Hive.box<Student>('students');
    if (box.isEmpty) { // Asegúrate de no insertar duplicados
      var students = [
        Student(
          firstName: 'NAYDA EBELIN',
          lastName: 'ALVARO CHIPA',
          dni: '90110001',
          gender: 'M',
          school: 5,
          profileImage: '',
          level: 7,
          grade: 27,
          section: 52,
        ),
        Student(
          firstName: 'RUMI RODOLFO',
          lastName: 'CARRILLO CABRERA',
          dni: '90110002',
          gender: 'H',
          school: 5,
          profileImage: '',
          level: 7,
          grade: 27,
          section: 52,
        ),
        // Agrega los otros estudiantes aquí
      ];

      for (var student in students) {
        await box.add(student);
      }
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoggingIn = true;
    });

    final String username = _usrNameController.text;
    final String password = _passwordController.text;

    // Construye el cuerpo de la solicitud en formato JSON
    final Map<String, dynamic> requestBody = {
      'username': username,
      'password': password,
    };

    final Uri apiUrl = Uri.parse('https://colecheck.com/api/login');

    try {
      final http.Response response = await http.post(
        apiUrl,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      // Imprime la respuesta de la API en la consola
      print('Respuesta de la API: ${response.body}');

      if (response.statusCode == 200) {
        // Si la autenticación es exitosa, navega a la página de escaneo de QR
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QRScannerPage(apiResponse: response.body),
          ),
        );
      } else {
        // Si hay un error de autenticación, muestra el mensaje de error
        setState(() {
          _isLoginTrue = true;
          _apiResponse = response.body;
        });
      }
    } catch (e) {
      print('Error en la solicitud de autenticación: $e');
      // Manejo de errores de red u otros
    } finally {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 150,
                  child: Center(
                    child: Image.asset("assets/logo.png", height: 70),
                  ),
                ),
                const Text(
                  "Inicia sesión en tu cuenta",
                  style: TextStyle(color: primaryColor, fontSize: 20),
                ),
                InputField(
                  hint: "Nombre de usuario",
                  icon: Icons.account_circle,
                  controller: _usrNameController,
                ),
                InputField(
                  hint: "Contraseña",
                  icon: Icons.lock,
                  controller: _passwordController,
                  passwordInvisible: true,
                ),
                ListTile(
                  horizontalTitleGap: 2,
                  title: const Text("Recuérdame"),
                  leading: Checkbox(
                    activeColor: primaryColor,
                    value: _isChecked,
                    onChanged: (value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                    },
                  ),
                ),
                Button(
                  label: "INICIAR SESIÓN",
                  press: _login,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes una cuenta?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("REGISTRARSE"),
                    ),
                  ],
                ),
                // Mensaje de error de acceso denegado en caso de que el nombre de usuario y la contraseña sean incorrectos
                _isLoginTrue
                    ? Text(
                        " El nombre de usuario o la contraseña son incorrectos",
                        style: TextStyle(color: Colors.red.shade900),
                      )
                    : const SizedBox(),
                // Diálogo de carga
                _isLoggingIn
                    ? Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
