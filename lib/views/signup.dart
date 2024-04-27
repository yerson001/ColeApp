import 'package:flutter/material.dart';
import 'package:coleapp/components/button.dart';
import 'package:coleapp/components/colors.dart';
import 'package:coleapp/components/textfield.dart';
import 'package:coleapp/models/users.dart';
import 'package:coleapp/views/login.dart';

import '../SQLite/database_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  //Controllers
  final fullName = TextEditingController();
  final email = TextEditingController();
  final usrName = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final db = DatabaseHelper();
  signUp() async {
    var res = await db.createUser(Users(
        fullName: fullName.text,
        email: email.text,
        usrName: usrName.text,
        password: password.text));
    if (res > 0) {
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Registrar una nueva cuenta",
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 55,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                InputField(
                    hint: "Nombre completo",
                    icon: Icons.person,
                    controller: fullName),
                InputField(hint: "Email", icon: Icons.email, controller: email),
                InputField(
                    hint: "Nombre de usuario",
                    icon: Icons.account_circle,
                    controller: usrName),
                InputField(
                    hint: "Contraseña",
                    icon: Icons.lock,
                    controller: password,
                    passwordInvisible: true),
                InputField(
                    hint: "Volver a ingresar la contraseña",
                    icon: Icons.lock,
                    controller: confirmPassword,
                    passwordInvisible: true),
                const SizedBox(height: 10),
                Button(
                    label: "REGISTRARSE",
                    press: () {
                      signUp();
                    }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿Ya tienes una cuenta?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()));
                        },
                        child: Text("INICIAR SESIÓN"))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
