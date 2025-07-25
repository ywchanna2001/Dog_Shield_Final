import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/presentation/widgets/bottom_navigation.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';

// Import the new service
import 'package:dogshield_ai/services/rabies_analysis_service.dart';
import 'package:video_player/video_player.dart';

class AIDetectionScreen extends StatefulWidget {
  const AIDetectionScreen({super.key});

  @override
  State<AIDetectionScreen> createState() => _AIDetectionScreenState();
}

class _AIDetectionScreenState extends State<AIDetectionScreen> with TickerProviderStateMixin {
  // State variables
  bool _isLoading = false; // Used for general loading states (picking/taking media)
  bool _isAnalyzing = false; // Specific to AI analysis
  bool _hasResult = false;
  String _errorMessage = '';

  XFile? _videoFile; // For video mode

  late AnimationController _animationController;

  // New state variables for video analysis
  final ImagePicker _picker = ImagePicker();
  final RabiesAnalysisService _analysisService = RabiesAnalysisService();
  AnalysisResult? _analysisResult; // Stores the detailed result from Gemini

  VideoPlayerController? _videoPlayerController; // For video preview

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoPlayerController?.dispose(); // Dispose video controller
    super.dispose();
  }

  // --- Media Picking Methods ---

  Future<void> _pickVideoFromGallery() async {
    setState(() {
      _isLoading = true;
      _hasResult = false;
      _errorMessage = '';
      _videoFile = null; // Clear previous video
      _analysisResult = null; // Clear previous analysis result
      _disposeVideoController(); // Dispose any existing video controller
    });

    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _videoFile = video;
          _initializeVideoPlayer(); // Initialize player for preview
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick video: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recordVideo() async {
    setState(() {
      _isLoading = true;
      _hasResult = false;
      _errorMessage = '';
      _videoFile = null; // Clear previous video
      _analysisResult = null; // Clear previous analysis result
      _disposeVideoController(); // Dispose any existing video controller
    });

    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        setState(() {
          _videoFile = video;
          _initializeVideoPlayer(); // Initialize player for preview
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to record video: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeVideoPlayer() {
    _disposeVideoController(); // Dispose any existing controller first
    if (_videoFile != null) {
      _videoPlayerController = VideoPlayerController.file(File(_videoFile!.path))
        ..initialize()
            .then((_) {
              setState(() {}); // Rerender to show the video player
              _videoPlayerController?.play(); // Auto-play
            })
            .catchError((e) {
              setState(() {
                _errorMessage = 'Failed to load video for preview: ${e.toString()}';
                _videoFile = null; // Clear video if it can't be played
              });
            });
    }
  }

  void _disposeVideoController() {
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
  }

  // --- Analysis Method (updated) ---

  Future<void> _analyzeMedia() async {
    setState(() {
      _isAnalyzing = true;
      _hasResult = false;
      _errorMessage = '';
    });

    try {
      if (_videoFile == null) {
        setState(() {
          _errorMessage = 'Please select or record a video first.';
          _isAnalyzing = false;
        });
        return;
      }
      // Call the RabiesAnalysisService for video
      final result = await _analysisService.analyzeVideo(_videoFile!);
      setState(() {
        _analysisResult = result;
        _hasResult = true;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Analysis failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _resetDetection() {
    setState(() {
      _videoFile = null;
      _analysisResult = null;
      _hasResult = false;
      _isLoading = false;
      _isAnalyzing = false;
      _errorMessage = '';
      _disposeVideoController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Rabies Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.detectionHistoryRoute);
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Media Preview
              _buildMediaPreview(),
              const SizedBox(height: 24),

              // Capture/Analysis Buttons or Result Section
              if (_isAnalyzing)
                _buildAnalyzingState() // Show Lottie animation when analyzing
              else if (_hasResult)
                _buildResultSection()
              else
                _buildCaptureButtons(),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(_errorMessage, style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Building Helper Methods ---

  Widget _buildMediaPreview() {
    if (_isAnalyzing) {
      return const SizedBox.shrink(); 
    }

    if (_videoFile == null) {
      return _buildEmptyState(icon: Icons.videocam, message: 'Pick or record a video of your dog for analysis.');
    } else {
      // Display video player
      return _videoPlayerController != null && _videoPlayerController!.value.isInitialized
          ? AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          )
          : Container(
            height: 300,
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: const Center(child: CircularProgressIndicator()),
          );
    }
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.primaryColor, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            '${AppConstants.animationPath}analyzing.json',
            width: 150,
            height: 150,
            controller: _animationController,
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing...',
            style: TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is analyzing your video',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.primaryColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Column(
      children: [
        // AI Detection Card - Main prompt
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Rabies Detection', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                  'Our AI can analyze dog behavior patterns from video to detect potential rabies symptoms.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickVideoFromGallery,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Select Video from Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _recordVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Record New Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Analyze Button (only shown if media is selected)
        if (_videoFile != null)
          ElevatedButton.icon(
            onPressed: _isLoading || _isAnalyzing ? null : _analyzeMedia,
            icon: const Icon(Icons.search),
            label: const Text('Analyze Video for Rabies Symptoms'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildResultSection() {
    if (_analysisResult == null) {
      return const SizedBox.shrink(); // Should not happen if _hasResult is true
    }

    // Determine color based on risk level
    Color resultColor;
    switch (_analysisResult!.riskLevel.toLowerCase()) {
      case 'high':
        resultColor = AppTheme.errorColor;
        break;
      case 'medium':
        resultColor = Colors.orange.shade700; // Use a distinct orange for medium
        break;
      default: // Low
        resultColor = AppTheme.successColor;
    }

    return Card(
      color: resultColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: resultColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              _analysisResult!.riskLevel.toLowerCase() == 'low' ? Icons.check_circle : Icons.warning_amber_rounded,
              size: 70,
              color: resultColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Rabies Risk: ${_analysisResult!.riskLevel}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: resultColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Observed Signs Section
            if (_analysisResult!.observedSigns.isNotEmpty) ...[
              const Text('Observed Signs:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ..._analysisResult!.observedSigns.map((sign) => Text('• $sign')).toList(),
              const Divider(height: 20, thickness: 1),
            ],
            const SizedBox(height: 24),
            Text(
              _analysisResult!.explanation,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            // Action buttons based on risk level
            if (_analysisResult!.riskLevel.toLowerCase() == 'high' ||
                _analysisResult!.riskLevel.toLowerCase() == 'medium')
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement find vet feature
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Finding nearby vets... (To be implemented)')));
                },
                icon: const Icon(Icons.local_hospital),
                label: const Text('Consult a Veterinarian'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement reminder setting
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Setting reminder... (To be implemented)')));
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Set Regular Check Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _resetDetection,
              icon: const Icon(Icons.refresh),
              label: const Text('Perform Another Detection'),
            ),
          ],
        ),
      ),
    );
  }
}