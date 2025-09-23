import 'package:flash_dash_delivery/auth/registerRider.dart';
import 'package:flash_dash_delivery/auth/resisterUser.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () {},
        child: Column(
          children: [
            FilledButton(
              onPressed: () {
                Get.to(() => const SignUpRiderScreen());
              },
              child: const Text('Register as Rider'),
            ),
            FilledButton(
              onPressed: () {
                Get.to(() => const SignUpUserScreen());
              },
              child: const Text('Register as User'),
            ),
          ],
        ),
      ),
    );
  }
}
