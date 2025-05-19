import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Recommender',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Recipe Recommender'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final picker = ImagePicker();
  Uint8List? _imageBytes;

  final _cuisineController = TextEditingController();
  final _dietController = TextEditingController();
  final _ingredientsController = TextEditingController();
  String _response = '';

  late final GenerativeModel geminiModel;

  @override
  void initState() {
    super.initState();
    geminiModel = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: const String.fromEnvironment('API_KEY'),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitPrompt() async {
    if (_imageBytes == null) return;

    final cuisine = _cuisineController.text;
    final diet = _dietController.text;
    final ingredients = _ingredientsController.text;

    final prompt = '''
Recommend a recipe for me based on the provided image.

I'm in the mood for the following types of cuisine: $cuisine
I have the following dietary restrictions: $diet
Optionally also include the following ingredients: $ingredients
''';

    try {
      final response = await geminiModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', _imageBytes!),
        ])
      ]);

      setState(() {
        _response = response.text ?? 'No response from AI.';
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            if (_imageBytes != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Image.memory(_imageBytes!, height: 200),
              ),
            TextField(
              controller: _cuisineController,
              decoration:
                  const InputDecoration(labelText: 'Preferred Cuisines'),
            ),
            TextField(
              controller: _dietController,
              decoration:
                  const InputDecoration(labelText: 'Dietary Restrictions'),
            ),
            TextField(
              controller: _ingredientsController,
              decoration:
                  const InputDecoration(labelText: 'Optional Ingredients'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitPrompt,
              child: const Text('Submit'),
            ),
            const SizedBox(height: 24),
            if (_response.isNotEmpty)
              Text(
                _response,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
