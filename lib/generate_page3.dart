import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'api_key.dart';

class GenerateDescriptionPage3 extends StatefulWidget {
  @override
  _GenerateDescriptionPage3State createState() => _GenerateDescriptionPage3State();
}

class _GenerateDescriptionPage3State extends State<GenerateDescriptionPage3> {
  File? _imageFile;
  String _description = 'Description will appear here';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();

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
        _description = 'Generating description...';
      });
      await generateDescription(_imageFile!);
    }
  }

  Future<void> generateDescription(File imageFile) async {
    final Uri apiUrl = Uri.parse('https://api-inference.huggingface.co/models/microsoft/swin-tiny-patch4-window7-224');
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
            final List<dynamic> result = jsonDecode(response.body);
            if (result.isNotEmpty) {
                // Extracting the top two labels with their scores
                String topDescriptions = '';
                for (int i = 0; i < result.length && i < 2; i++) {
                    final label = result[i]['label'];
                    final score = result[i]['score'];
                    topDescriptions += '${label} ${(score*100).toStringAsFixed(1)} % \n'; /*(Score: ${score.toStringAsFixed(2)})*/
                }
                setState(() {
                    _description = topDescriptions.isNotEmpty ? topDescriptions.trim() : 'No description generated';
                });
            } else {
                setState(() {
                    _description = 'No description generated';
                });
            }
        } else {
            setState(() {
                _description = 'Error generating description: ${response.statusCode} ${response.body}';
            });
        }
    } catch (e) {
        setState(() {
            _description = 'Exception: $e';
        });
    } finally {
        setState(() {
            _isLoading = false;
        });
    }
}



  void _speakCaption() async {
    if (_description.isNotEmpty &&
        _description != 'Description will appear here.' &&
        _description != 'Generating description...' &&
        !_isLoading) {
      await _flutterTts.speak(_description);
    }
  }

  void _resetPage() {
    setState(() {
      _imageFile = null;
      _description = 'Description will appear here.';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('swin-tiny-patch4-window7-224', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple[200],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
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
                    ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                    : Image.file(_imageFile!),
              ),
            ),
            SizedBox(height: 40),
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
                      _description,
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
