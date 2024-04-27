import 'package:flutter/material.dart';
import 'package:coleapp/components/button.dart';
import 'package:coleapp/components/colors.dart';
import 'package:coleapp/components/textfield.dart';
import 'package:coleapp/models/users.dart';
import 'package:coleapp/views/profile.dart';
import 'package:coleapp/views/signup.dart';

import '../SQLite/database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //Our controllers
  //Controller is used to take the value from user and pass it to database
  final usrName = TextEditingController();
  final password = TextEditingController();

  bool isChecked = false;
  bool isLoginTrue = false;

  final db = DatabaseHelper();
  //Login Method
  //We will take the value of text fields using controllers in order to verify whether details are correct or not
  login() async {
    Users? usrDetails = await db.getUser(usrName.text);
    var res = await db
        .authenticate(Users(usrName: usrName.text, password: password.text));
    if (res == true) {
      //If result is correct then go to profile or home
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Profile(profile: usrDetails)));
    } else {
      //Otherwise show the error message
      setState(() {
        isLoginTrue = true;
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
                  height: 150, // Ajusta este valor según sea necesario
                  child: Center(
                    child: Image.asset("assets/logo.png", height: 70), // Ajusta el valor de height según sea necesario
                  ),
                ),
                const Text(
                  "Inicia sesión en tu cuenta",
                  style: TextStyle(color: primaryColor, fontSize: 20),
                ),
                InputField(
                    hint: "Nombre de usuario",
                    icon: Icons.account_circle,
                    controller: usrName),
                InputField(
                    hint: "Contraseña",
                    icon: Icons.lock,
                    controller: password,
                    passwordInvisible: true),

                ListTile(
                  horizontalTitleGap: 2,
                  title: const Text("Recuérdame"),
                  leading: Checkbox(
                    activeColor: primaryColor,
                    value: isChecked,
                    onChanged: (value) {
                      setState(() {
                        isChecked = !isChecked;
                      });
                    },
                  ),
                ),

                //Our login button
                Button(
                    label: "INICIAR SESIÓN",
                    press: () {
                      login();
                    }),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes una cuenta?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignupScreen()));
                        },
                        child: const Text("REGISTRARSE"))
                  ],
                ),

                // Access denied message in case when your username and password is incorrect
                //By default we must hide it
                //When login is not true then display the message
                isLoginTrue
                    ? Text(
                        " El nombre de usuario o la contraseña son incorrectos",
                        style: TextStyle(color: Colors.red.shade900),
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
