import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'api_key.dart';

class GenerateCaptionPage extends StatefulWidget {
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
      // Read the image file as bytes
      final bytes = await imageFile.readAsBytes();

      // Send POST request with the binary data
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

      // Check if the response is successful
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
        _caption != 'Caption generated here' &&
        _caption != 'Generating caption...' &&
        !_isLoading) {
      await _flutterTts.speak(_caption);
    }
  }

  void _resetPage() {
    setState(() {
      _imageFile = null;
      _caption = 'Caption generated here';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Caption', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple[200], 
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Align(
            //   alignment: Alignment.topLeft,
            //   child: IconButton(
            //     icon: Icon(Icons.arrow_back, color: Colors.purple),
            //     onPressed: () {
            //       Navigator.pop(context);
            //     },
            //   ),
            // ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: _imageFile == null
                    ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                    : Image.file(_imageFile!),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200], 
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Text(
                      _caption,
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.mic),
              label: Text('Speak Caption'),
              onPressed: _speakCaption,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.purple[200],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              child: Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }
}

