class StudentExamModel {
  final int id;
  final int studentId;
  final int examId;
  final String status;
  final DateTime? startTime;
  final DateTime? submitTime;
  final double score;
  final int tabSwitchesCount;
  final int fullscreenExitsCount;
  final bool autoSubmitted;
  final String? studentName;
  final String? studentEmail;
  final String? examTitle;
  final int? durationMinutes;
  final double? totalMarks;
  final double? passingMarks;
  final bool? antiCheatingEnabled;

  StudentExamModel({
    required this.id,
    required this.studentId,
    required this.examId,
    required this.status,
    this.startTime,
    this.submitTime,
    required this.score,
    required this.tabSwitchesCount,
    required this.fullscreenExitsCount,
    required this.autoSubmitted,
    this.studentName,
    this.studentEmail,
    this.examTitle,
    this.durationMinutes,
    this.totalMarks,
    this.passingMarks,
    this.antiCheatingEnabled,
  });

  factory StudentExamModel.fromJson(Map<String, dynamic> json) {
    return StudentExamModel(
      id: int.parse(json['id'].toString()),
      studentId: int.parse(json['student_id'].toString()),
      examId: int.parse(json['exam_id'].toString()),
      status: json['status'] as String,
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'].toString()) : null,
      submitTime: json['submit_time'] != null ? DateTime.parse(json['submit_time'].toString()) : null,
      score: double.parse(json['score']?.toString() ?? '0.00'),
      tabSwitchesCount: int.parse(json['tab_switches_count']?.toString() ?? '0'),
      fullscreenExitsCount: int.parse(json['fullscreen_exits_count']?.toString() ?? '0'),
      autoSubmitted: json['auto_submitted'].toString() == '1' || json['auto_submitted'] == true,
      studentName: json['student_name'] as String?,
      studentEmail: json['student_email'] as String?,
      examTitle: json['exam_title'] as String?,
      durationMinutes: json['duration_minutes'] != null ? int.parse(json['duration_minutes'].toString()) : null,
      totalMarks: json['total_marks'] != null ? double.parse(json['total_marks'].toString()) : null,
      passingMarks: json['passing_marks'] != null ? double.parse(json['passing_marks'].toString()) : null,
      antiCheatingEnabled: json['anti_cheating_enabled'] != null 
          ? (json['anti_cheating_enabled'].toString() == '1' || json['anti_cheating_enabled'] == true) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'exam_id': examId,
      'status': status,
      'start_time': startTime?.toIso8601String(),
      'submit_time': submitTime?.toIso8601String(),
      'score': score,
      'tab_switches_count': tabSwitchesCount,
      'fullscreen_exits_count': fullscreenExitsCount,
      'auto_submitted': autoSubmitted ? 1 : 0,
      'student_name': studentName,
      'student_email': studentEmail,
      'exam_title': examTitle,
      'duration_minutes': durationMinutes,
      'total_marks': totalMarks,
      'passing_marks': passingMarks,
      'anti_cheating_enabled': antiCheatingEnabled != null ? (antiCheatingEnabled! ? 1 : 0) : null,
    };
  }

  bool get isPassed {
    if (passingMarks == null) return score >= 0.00;
    return score >= passingMarks!;
  }
}

class AnswerModel {
  final int id;
  final int studentExamId;
  final int questionId;
  final int? selectedOptionId;
  final String? answerText;
  final bool isCorrect;
  final double marksObtained;
  final String questionText;
  final String questionType;
  final double qMarks;
  final String? selectedOptionText;

  AnswerModel({
    required this.id,
    required this.studentExamId,
    required this.questionId,
    this.selectedOptionId,
    this.answerText,
    required this.isCorrect,
    required this.marksObtained,
    required this.questionText,
    required this.questionType,
    required this.qMarks,
    this.selectedOptionText,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: int.parse(json['id'].toString()),
      studentExamId: int.parse(json['student_exam_id'].toString()),
      questionId: int.parse(json['question_id'].toString()),
      selectedOptionId: json['selected_option_id'] != null ? int.parse(json['selected_option_id'].toString()) : null,
      answerText: json['answer_text'] as String?,
      isCorrect: json['is_correct'].toString() == '1' || json['is_correct'] == true,
      marksObtained: double.parse(json['marks_obtained']?.toString() ?? '0.00'),
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String? ?? 'mcq',
      qMarks: double.parse(json['q_marks']?.toString() ?? '1.00'),
      selectedOptionText: json['selected_option_text'] as String?,
    );
  }
}

class LeaderboardModel {
  final String name;
  final double totalPoints;
  final int examsTaken;

  LeaderboardModel({
    required this.name,
    required this.totalPoints,
    required this.examsTaken,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      name: json['name'] as String,
      totalPoints: double.parse(json['total_points']?.toString() ?? '0.00'),
      examsTaken: int.parse(json['exams_taken']?.toString() ?? '0'),
    );
  }
}
