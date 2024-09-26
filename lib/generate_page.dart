import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'api_key.dart';

class GenerateCaptionPage extends StatefulWidget {
  const GenerateCaptionPage({super.key});

  @override
  _GenerateCaptionPageState createState() => _GenerateCaptionPageState();
}

class _GenerateCaptionPageState extends State<GenerateCaptionPage> {
  File? _imageFile;
  String _caption = 'Caption generated here';
  bool _isLoading = false;
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isLoading = true;
        _caption = 'Generating caption...';
      });
      await generateCaption(_imageFile!);
    }
  }

  Future<void> generateCaption(File imageFile) async {
    final Uri apiUrl = Uri.parse('https://api-inference.huggingface.co/models/nlpconnect/vit-gpt2-image-captioning');
    final String apiKey = HUGGING_FACE_USER_TOKEN;

    try {
      final bytes = await imageFile.readAsBytes();

      final response = await http.post(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/octet-stream', 
        },
        body: bytes,
      );

      
      print('Response Status Code: ${response.statusCode}');
      print('Response Data: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _caption = result[0]['generated_text']; 
          _isLoading = false;
        });
      } else {
        setState(() {
          _caption = 'Error generating caption: ${response.statusCode} ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _caption = 'Exception: $e';
        _isLoading = false;
      });
    }
  }

  void _speakCaption() async {
    if (_caption.isNotEmpty &&
        _caption != 'Description will appear here.' &&
        _caption != 'Generating caption...' &&
        !_isLoading) {
      await _flutterTts.speak(_caption);
    }
  }

  void _resetPage() {
    setState(() {
      _imageFile = null;
      _caption = 'Description will appear here.';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('vit-gpt2', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple[200], 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: _imageFile == null
                    ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                    : Image.file(_imageFile!),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200], 
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _caption,
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text('Speak Description'),
              onPressed: _speakCaption,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.purple[200],
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Reset'),
              onPressed: _resetPage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: Colors.purple[200],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

