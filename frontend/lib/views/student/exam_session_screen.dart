import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../constants/app_colors.dart';

class ExamSessionScreen extends StatefulWidget {
  const ExamSessionScreen({super.key});

  @override
  State<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends State<ExamSessionScreen> with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set immersive sticky full-screen mode on launch
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Restore normal system overlays upon leaving the exam
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Hook to detect when student switches apps, backgrounds the app, or pulls down notification panel
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final sp = Provider.of<StudentProvider>(context, listen: false);
      if (sp.antiCheatingEnabled && !_submitted) {
        // Log tab switch infraction in database
        sp.logCheatingIncident('tab_switch', 'App minimized or backgrounded by student.');
        
        // Present warning modal alert
        _showCheatingWarningDialog();
      }
    }
  }

  void _showCheatingWarningDialog() {
    final sp = Provider.of<StudentProvider>(context, listen: false);
    final remainingSwitches = sp.maxTabSwitches - sp.tabSwitches;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // prevent closing by back key
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Cheating Warning', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
            content: Text(
              'A tab-switch or app minimization event was detected!\n\n'
              'SmartExam monitors app environment focus to protect integrity.\n\n'
              'Remaining violations permitted: $remainingSwitches / ${sp.maxTabSwitches}\n'
              'Crossing this limit will trigger automatic submission.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I Understand, Resume Test'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Format seconds to MM:SS
  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<StudentProvider>(context);

    // Watch for automatic submissions (e.g. timeout or infraction count exceeded)
    if (sp.examSubmitted && !_submitted) {
      _submitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAutoSubmitDialog();
      });
    }

    if (sp.activeQuestions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = sp.activeQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / sp.activeQuestions.length;

    return WillPopScope(
      onWillPop: () async {
        // Block hardware/swipe back button inside exam session
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _formatDuration(sp.secondsRemaining),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Text(
                'Violations: ${sp.tabSwitches} / ${sp.maxTabSwitches}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => _confirmSubmitDialog(sp),
              child: const Text('Submit Exam'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            // Linear Progress Bar
            LinearProgressIndicator(value: progress, minHeight: 6),
            
            // Question Navigation Horizontal Grid
            _buildNavigationGrid(sp),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${_currentQuestionIndex + 1} of ${sp.activeQuestions.length}',
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Marks: ${question.marks}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Question text
                        Text(
                          question.questionText,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
                        ),
                        const SizedBox(height: 30),

                        // Options List
                        ...List.generate(question.options.length, (optIdx) {
                          final opt = question.options[optIdx];
                          final isSelected = question.selectedOptionId == opt.id;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () => sp.selectAnswer(_currentQuestionIndex, opt.id),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 22,
                                      width: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : Colors.grey,
                                          width: 2,
                                        ),
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        opt.optionText,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _currentQuestionIndex > 0
                        ? () => setState(() => _currentQuestionIndex--)
                        : null,
                    child: const Text('Previous'),
                  ),
                  OutlinedButton(
                    onPressed: _currentQuestionIndex < sp.activeQuestions.length - 1
                        ? () => setState(() => _currentQuestionIndex++)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGrid(StudentProvider sp) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sp.activeQuestions.length,
        itemBuilder: (context, index) {
          final q = sp.activeQuestions[index];
          final isCurrent = index == _currentQuestionIndex;
          final isAnswered = q.selectedOptionId != null;

          Color btnColor = Colors.grey.withOpacity(0.12);
          Color textColor = Colors.black87;
          if (isAnswered) {
            btnColor = AppColors.primary.withOpacity(0.12);
            textColor = AppColors.primary;
          }
          if (isCurrent) {
            btnColor = AppColors.primary;
            textColor = Colors.white;
          }

          return GestureDetector(
            onTap: () => setState(() => _currentQuestionIndex = index),
            child: Container(
              width: 44,
              margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(8),
                border: isCurrent
                    ? null
                    : Border.all(color: isAnswered ? AppColors.primary.withOpacity(0.3) : Colors.transparent),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark && !isCurrent
                      ? Colors.white70
                      : textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmSubmitDialog(StudentProvider sp) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Assessment'),
          content: const Text(
            'Are you sure you want to submit your examination?\n\n'
            'You cannot modify your choices after submission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await sp.submitExam();
                  _showResultSummary(sp);
                } catch (e) {
                  _showError(e.toString());
                }
              },
              child: const Text('Yes, Submit'),
            )
          ],
        );
      },
    );
  }

  void _showAutoSubmitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Exam Auto-Submitted'),
            content: const Text(
              'Your examination session has been auto-submitted.\n\n'
              'This happens automatically when the countdown timer expires, or if focus violations limits were crossed.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to student dashboard
                },
                child: const Text('Return to Dashboard'),
              )
            ],
          ),
        );
      },
    );
  }

  void _showResultSummary(StudentProvider sp) {
    // Navigate back to Dashboard upon submit confirmation
    Navigator.pop(context);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}
// Helper color coupon
class ColorsCoupon {
  static Color get black8 => Colors.black87;
}
extension on Colors {
  static Color get black8 => Colors.black87;
}
