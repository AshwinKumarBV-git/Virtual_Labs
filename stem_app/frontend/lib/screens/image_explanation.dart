import 'package:flutter/material.dart';
import 'dart:io'; // For File
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonDecode
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart'; // Needed for TTS file caching potential

// Enum for TTS State
enum TtsState { playing, stopped, paused }

class ImageExplanationScreen extends StatefulWidget {
  const ImageExplanationScreen({super.key});

  @override
  State<ImageExplanationScreen> createState() => _ImageExplanationScreenState();
}

class _ImageExplanationScreenState extends State<ImageExplanationScreen> {
  File? _imageFile;
  String _explanationText = "";
  String? _errorMessage; // Specific state for errors
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  late FlutterTts flutterTts;
  TtsState _ttsState = TtsState.stopped; // State for TTS button

  // IMPORTANT: Replace with your actual backend URL
  // Use 10.0.2.2 for Android Emulator accessing host localhost
  // Use machine's local network IP for physical devices
  // Use 127.0.0.1 (localhost) for desktop app accessing local backend
  final String _backendUrl = 'http://192.168.135.16:8000'; // <<< REPLACE with your PC's actual Local IP

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  @override
  void dispose() {
    flutterTts.stop(); // Ensure TTS stops when screen is disposed
    super.dispose();
  }

  Future<void> _initializeTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setSharedInstance(true);

    // Set TTS handlers
    flutterTts.setStartHandler(() {
      if (mounted) { // Check if widget is still in the tree
        setState(() {
          _ttsState = TtsState.playing;
        });
      }
    });

    flutterTts.setCompletionHandler(() {
       if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
        });
      }
    });

    flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          print("TTS Error: $msg");
          _ttsState = TtsState.stopped;
          _errorMessage = "Text-to-speech error occurred."; // Show error in UI
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Text-to-speech failed.")),
        );
      }
    });

    // Optional: Set language if needed, though we set it before speaking
    // await flutterTts.setLanguage("en-US");
  }


  Future<void> _pickImage(ImageSource source) async {
    // Stop TTS if playing when picking a new image
    if (_ttsState == TtsState.playing) {
      await _stopTts();
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null && mounted) { // Check mounted after await
        setState(() {
          _imageFile = File(pickedFile.path);
          _explanationText = ""; // Clear previous explanation
          _errorMessage = null; // Clear previous error
          _isLoading = false;
          _ttsState = TtsState.stopped; // Reset TTS state
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) { // Check mounted after await
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: ${e.toString()}")),
        );
        setState(() {
           _errorMessage = "Failed to pick image."; // Show error in UI
        });
      }
    }
  }

  Future<void> _getExplanation() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noImageSelected)),
      );
      return;
    }
    // Stop TTS before fetching new explanation
    if (_ttsState == TtsState.playing) {
      await _stopTts();
    }

    setState(() {
      _isLoading = true;
      _explanationText = ""; // Clear previous explanation
      _errorMessage = null; // Clear previous error
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/image'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60)); // Longer timeout
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return; // Check if widget is still mounted after async operation

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _explanationText = data['explanation'] ?? 'No explanation received.';
          _errorMessage = null; // Clear error on success
          _isLoading = false;
        });
      } else {
         // Try to parse error detail from backend response
         String errorDetail = response.body;
         try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            errorDetail = errorData['detail'] ?? response.body;
         } catch (_) {
            // Keep original body if it's not JSON
         }
        print('Error from backend: ${response.statusCode} $errorDetail');
        setState(() {
          _explanationText = ""; // Clear any partial explanation
          _errorMessage = "Error ${response.statusCode}: $errorDetail"; // Use backend error
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error sending image/getting explanation: $e");
       if (!mounted) return; // Check mounted after catching error

      setState(() {
        String errorMsg;
        if (e is SocketException) {
          errorMsg = AppLocalizations.of(context)!.offlineWarning;
        } else if (e is http.ClientException) {
           errorMsg = "Network error: Failed to connect to server.";
        } else {
           errorMsg = AppLocalizations.of(context)!.explanationError; // Generic error
        }
         _explanationText = "";
         _errorMessage = errorMsg;
         _isLoading = false;
      });
    }
  }

  Future<void> _speakExplanation() async {
    if (_explanationText.isNotEmpty && !_isLoading && _errorMessage == null) {
       if (_ttsState == TtsState.playing) {
         await _stopTts(); // If playing, stop it
       } else {
          try {
            // Set language before speaking
            await flutterTts.setLanguage("en-US"); // Use English specifically
            await flutterTts.setPitch(1.0);
            // Start speaking
            await flutterTts.speak(_explanationText);
            // State update handled by setStartHandler
          } catch (e) {
             print("Error starting TTS: $e");
             if (mounted) {
               setState(() {
                 _errorMessage = "Text-to-speech failed to start.";
                 _ttsState = TtsState.stopped;
               });
             }
          }
       }
    }
  }

   Future<void> _stopTts() async {
    var result = await flutterTts.stop();
    if (result == 1 && mounted) { // result == 1 means success
      setState(() {
        _ttsState = TtsState.stopped;
      });
    }
  }

  // --- Modular UI Builder Functions --- //

  Widget _buildImageSelectionArea(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: Text(l10n.captureImageButton),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: Text(l10n.uploadImageButton),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Semantics(
        label: "Selected image preview",
        child: Container(
          height: 250,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10.0), // Added margin
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12), // Increased rounding
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), // Subtle background
          ),
          child: _imageFile != null
              ? ClipRRect( // Clip the image to the rounded corners
                  borderRadius: BorderRadius.circular(11), // Slightly less than container
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.contain, // Use contain to see whole image
                    errorBuilder: (context, error, stackTrace) {
                      // Handle potential file reading errors
                      return Center(
                        child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
                             const SizedBox(height: 8),
                             Text("Error loading image", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                           ],
                        ));
                    },
                  ),
                )
              : Center( // Placeholder when no image is selected
                  child: Icon(
                    Icons.image_search_outlined, // Changed icon
                    size: 70,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
        ),
      ),
    );
  }

   Widget _buildSubmitButton(AppLocalizations l10n, ThemeData theme) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 10.0),
       child: ElevatedButton.icon(
         icon: const Icon(Icons.science_outlined), // Added relevant icon
         label: Text(l10n.getExplanationButton),
         style: ElevatedButton.styleFrom(
           padding: const EdgeInsets.symmetric(vertical: 16.0),
           textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Adjusted style
           backgroundColor: theme.colorScheme.primary, // Primary color for action
           foregroundColor: theme.colorScheme.onPrimary, // Text color on primary
         ),
         onPressed: (_imageFile != null && !_isLoading) ? _getExplanation : null, // Disable if no image or loading
       ),
     );
   }

   Widget _buildExplanationArea(AppLocalizations l10n, ThemeData theme) {
     bool canSpeak = _explanationText.isNotEmpty && !_isLoading && _errorMessage == null;

     return Card( // Use Card for elevation and distinct area
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox( // Ensure minimum height
            constraints: const BoxConstraints(minHeight: 120),
            child: Semantics(
              liveRegion: true, // Announce changes
              child: _isLoading
                  ? _buildLoadingIndicator(l10n) // Show loading indicator
                  : _errorMessage != null
                      ? _buildErrorDisplay(l10n, theme) // Show error message
                      : _buildExplanationContent(l10n, theme, canSpeak), // Show explanation
            ),
          ),
        ),
      );
   }

    Widget _buildLoadingIndicator(AppLocalizations l10n) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.explanationLoading,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Widget _buildErrorDisplay(AppLocalizations l10n, ThemeData theme) {
      return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
             const SizedBox(height: 8),
             Text(
               _errorMessage!,
               style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 16),
             // Optional: Add a retry button if applicable
             if (_imageFile != null) // Only show retry if an image was selected
               TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retryButtonLabel ?? "Retry"), // Assuming 'retryButtonLabel' is in your l10n files
                  onPressed: _getExplanation,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
               )
           ],
         ),
       );
    }

   Widget _buildExplanationContent(AppLocalizations l10n, ThemeData theme, bool canSpeak) {
     String displayText = _explanationText.isEmpty && _imageFile != null
         ? 'Press "${l10n.getExplanationButton}" to analyze the image.'
         : _explanationText.isEmpty // Handle case where no image selected yet
            ? 'Select an image using the buttons above.'
            : _explanationText;

     return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              displayText,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4), // Improved line spacing
            ),
          ),
          // Only show TTS button if there is valid text and not loading/error
          if (canSpeak)
            Semantics(
              label: _ttsState == TtsState.playing ? "Stop speaking" : "Speak explanation",
              child: IconButton(
                icon: Icon(_ttsState == TtsState.playing ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
                onPressed: _speakExplanation, // Will call speak or stop based on state
                tooltip: _ttsState == TtsState.playing ? "Stop" : "Speak",
                color: theme.colorScheme.primary,
                iconSize: 30, // Slightly larger icon
              ),
            ),
        ],
      );
   }

  // --- Main Build Method --- //
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.imageExplanationTitle),
        backgroundColor: theme.colorScheme.surfaceContainerHighest, // Adjusted color
        elevation: 1, // Subtle elevation
      ),
      body: SafeArea( // Ensure content avoids notches/status bars
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSelectionArea(l10n),
              _buildImagePreview(),
              _buildSubmitButton(l10n, theme),
              _buildExplanationArea(l10n, theme),
            ],
          ),
        ),
      ),
    );
  }
} 