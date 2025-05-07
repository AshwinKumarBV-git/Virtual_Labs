import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode

// Data structure for a single quiz question
class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class QuizScreen extends StatefulWidget {
  final String labId; // e.g., 'Density', 'Soil_pH', 'Osmosis'

  const QuizScreen({required this.labId, super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions; // Questions for the current lab
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex; // Index of the selected Radio button
  Map<int, int?> _answers = {}; // Store selected answer index for each question index
  int _score = 0;
  bool _quizCompleted = false;

  // Hardcoded quiz data (Replace with API call or more robust loading later)
  final Map<String, List<QuizQuestion>> _allQuizzes = {
    'Density': [
      QuizQuestion(
        questionText: "If mass increases but volume stays the same, density...",
        options: ["Increases", "Decreases", "Stays the Same"],
        correctAnswerIndex: 0,
      ),
      QuizQuestion(
        questionText: "Which unit is commonly used for density?",
        options: ["kg", "m/s²", "g/cm³"],
        correctAnswerIndex: 2,
      ),
    ],
    'Soil_pH': [
      QuizQuestion(
        questionText: "Reddish color with a natural indicator like turmeric suggests the soil is...",
        options: ["Acidic", "Neutral", "Basic/Alkaline"],
        correctAnswerIndex: 2,
      ),
      QuizQuestion(
        questionText: "Most common plants prefer which type of soil pH?",
        options: ["Highly Acidic", "Neutral (around 6.5-7.0)", "Highly Alkaline"],
        correctAnswerIndex: 1,
      ),
    ],
    'Osmosis': [
      QuizQuestion(
        questionText: "A potato slice shrinks in saltwater because water moves...",
        options: ["Into the potato cells", "Out of the potato cells", "Does not move"],
        correctAnswerIndex: 1,
      ),
      QuizQuestion(
        questionText: "What is the movement of water across a semi-permeable membrane called?",
        options: ["Diffusion", "Active Transport", "Osmosis"],
        correctAnswerIndex: 2,
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _questions = _allQuizzes[widget.labId] ?? []; // Get questions for this lab
  }

  void _selectAnswer(int? index) {
    setState(() {
      _selectedAnswerIndex = index;
      _answers[_currentQuestionIndex] = index; // Store selection for this question
    });
  }

  void _nextQuestion() {
    if (_selectedAnswerIndex == null) {
      // Show a snackbar or message to select an answer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.quizSelectAnswerPrompt)),
      );
      return;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = _answers[_currentQuestionIndex]; // Load previous selection if any
      });
    } else {
      // Last question, should trigger submit logic (handled by button text change)
      _submitQuiz();
    }
  }

  // Map labId string to backend integer ID
  int _getBackendLabId(String labId) {
    switch (labId) {
      case 'Density': return 1;
      case 'Soil_pH': return 2;
      case 'Osmosis': return 3;
      default: return 0; // Should not happen
    }
  }

  Future<void> _submitQuiz() async {
    if (_selectedAnswerIndex == null && !_answers.containsKey(_currentQuestionIndex)) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.quizSelectAnswerPrompt)),
         );
         return;
    }

    // Calculate score
    _score = 0;
    _answers.forEach((questionIndex, answerIndex) {
      if (answerIndex != null &&
          answerIndex == _questions[questionIndex].correctAnswerIndex) {
        _score++;
      }
    });

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${widget.labId}_quiz_score', _score);
      await prefs.setString('${widget.labId}_quiz_timestamp', DateTime.now().toIso8601String());
      print('Quiz score saved locally for ${widget.labId}: $_score');
    } catch (e) {
      print('Error saving quiz score locally: $e');
      // Handle error if needed
    }

    // Attempt to sync with backend
    final int backendLabId = _getBackendLabId(widget.labId);
    if (backendLabId > 0) {
      // Replace with your actual backend IP/URL
      // Use 10.0.2.2 for Android Emulator accessing host localhost
      // Use machine's local network IP for physical devices/web/desktop
      const String backendUrl = 'http://10.0.2.2:8000/quiz'; // <<< CHANGE IF NEEDED
      try {
        final response = await http.post(
          Uri.parse(backendUrl),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(<String, int>{
            'lab_id': backendLabId,
            'score': _score,
          }),
        ).timeout(const Duration(seconds: 5)); // Add a timeout

        if (response.statusCode == 200) {
          print('Quiz score synced with backend successfully.');
        } else {
          print('Failed to sync quiz score. Status: ${response.statusCode}, Body: ${response.body}');
          // Optionally show feedback to user about sync failure
        }
      } catch (e) {
        print('Error syncing quiz score with backend: $e');
        // Handle network errors gracefully (e.g., offline scenario)
      }
    }

    setState(() {
      _quizCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz: ${widget.labId}')),
        body: const Center(child: Text('No questions found for this lab.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.labId}'),
        backgroundColor: theme.colorScheme.secondaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _quizCompleted ? _buildResultView(l10n, theme) : _buildQuestionView(l10n, theme),
      ),
    );
  }

  // Builds the view for displaying the current question
  Widget _buildQuestionView(AppLocalizations l10n, ThemeData theme) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final bool isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${_currentQuestionIndex + 1}/${_questions.length}',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Text(
          currentQuestion.questionText,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        // Use Expanded + ListView for options if they might overflow
        Expanded(
          child: ListView.builder(
            itemCount: currentQuestion.options.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: RadioListTile<int>(
                  title: Text(currentQuestion.options[index], style: theme.textTheme.bodyLarge),
                  value: index,
                  groupValue: _selectedAnswerIndex,
                  onChanged: _selectAnswer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: theme.textTheme.titleLarge,
          ),
          onPressed: isLastQuestion ? _submitQuiz : _nextQuestion,
          child: Text(isLastQuestion ? l10n.quizSubmitButton : l10n.quizNextButton),
        ),
      ],
    );
  }

  // Builds the view for displaying the quiz results
  Widget _buildResultView(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.quizScoreFeedback(_score.toString(), _questions.length.toString()),
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
              textStyle: theme.textTheme.titleLarge,
            ),
            onPressed: () {
              // Navigate back to Lab Selection screen (pop twice: Quiz -> Specific Lab -> Selection)
              int popCount = 0;
              Navigator.of(context).popUntil((route) => popCount++ == 2);
              // Or navigate directly if routes allow:
              // Navigator.popUntil(context, ModalRoute.withName('/lab-selection'));
              // Or simply pop once if that's the desired flow:
              // Navigator.pop(context);
            },
            child: Text(l10n.quizBackButton),
          ),
        ],
      ),
    );
  }
} 