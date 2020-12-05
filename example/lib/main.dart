import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_voice_processor/flutter_voice_processor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isButtonDisabled = false;
  bool _isProcessing = false;
  VoiceProcessor _voiceProcessor;
  Function _removeListener;

  @override
  void initState() {
    super.initState();
    _initVoiceProcessor();
  }

  void _initVoiceProcessor() async {
    _voiceProcessor = VoiceProcessor.getVoiceProcessor(512, 16000);

    if (await _voiceProcessor.hasRecordAudioPermission()) {
      print("Recording permission granted!");
    } else {
      print("Recording permission not granted");
    }
  }

  Future<void> _startProcessing() async {
    this.setState(() {
      _isButtonDisabled = true;
    });

    _removeListener = _voiceProcessor.addListener(_onBufferReceived);
    await _voiceProcessor.start();

    this.setState(() {
      _isButtonDisabled = false;
      _isProcessing = true;
    });
  }

  void _onBufferReceived(dynamic eventData) {
    print(eventData);
  }

  Future<void> _stopProcessing() async {
    this.setState(() {
      _isButtonDisabled = true;
    });

    await _voiceProcessor.stop();
    _removeListener();

    this.setState(() {
      _isButtonDisabled = false;
      _isProcessing = true;
    });
  }

  void _toggleProcessing() async {
    if (_isProcessing) {
      await _stopProcessing();
    } else {
      await _startProcessing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Processor'),
        ),
        body: Center(
          child: _buildToggleProcessingButton(),
        ),
      ),
    );
  }

  Widget _buildToggleProcessingButton() {
    return new RaisedButton(
      onPressed: _isButtonDisabled ? null : _toggleProcessing,
      child: Text(_isProcessing ? "Stop" : "Start",
          style: TextStyle(fontSize: 20)),
    );
  }
}
