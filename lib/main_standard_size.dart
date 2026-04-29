import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'User 3D Market Place/standard_sizes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SmartFitao AI – Standard Size',
    home: StandardSizesScreen(
      product: {
        'title': 'Classic White Shalwar Kameez',
        'price': 5490,
        'category': 'Shalwar Kameez',
      },
      onBack: () {},
    ),
  ));
}
