class ExamModel {
  final int id;
  final String title;
  final String? description;
  final int subjectId;
  final int teacherId;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final double totalMarks;
  final double passingMarks;
  final double negativeMarkingFactor;
  final bool randomizeQuestions;
  final bool randomizeOptions;
  final bool antiCheatingEnabled;
  final bool isPublished;
  final String? qrCodeToken;
  final String? subjectName;
  final String? teacherName;
  final String? attemptStatus; // 'registered', 'ongoing', 'submitted', 'abandoned', null
  final double? score; // student's score if attempted

  ExamModel({
    required this.id,
    required this.title,
    this.description,
    required this.subjectId,
    required this.teacherId,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.totalMarks,
    required this.passingMarks,
    required this.negativeMarkingFactor,
    required this.randomizeQuestions,
    required this.randomizeOptions,
    required this.antiCheatingEnabled,
    required this.isPublished,
    this.qrCodeToken,
    this.subjectName,
    this.teacherName,
    this.attemptStatus,
    this.score,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: int.parse(json['id'].toString()),
      title: json['title'] as String,
      description: json['description'] as String?,
      subjectId: int.parse(json['subject_id'].toString()),
      teacherId: int.parse(json['teacher_id'].toString()),
      durationMinutes: int.parse(json['duration_minutes'].toString()),
      startTime: DateTime.parse(json['start_time'].toString()),
      endTime: DateTime.parse(json['end_time'].toString()),
      totalMarks: double.parse(json['total_marks'].toString()),
      passingMarks: double.parse(json['passing_marks'].toString()),
      negativeMarkingFactor: double.parse(json['negative_marking_factor']?.toString() ?? '0.00'),
      randomizeQuestions: json['randomize_questions'].toString() == '1' || json['randomize_questions'] == true,
      randomizeOptions: json['randomize_options'].toString() == '1' || json['randomize_options'] == true,
      antiCheatingEnabled: json['anti_cheating_enabled'].toString() == '1' || json['anti_cheating_enabled'] == true,
      isPublished: json['is_published'].toString() == '1' || json['is_published'] == true,
      qrCodeToken: json['qr_code_token'] as String?,
      subjectName: json['subject_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      attemptStatus: json['attempt_status'] as String?,
      score: json['score'] != null ? double.parse(json['score'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'duration_minutes': durationMinutes,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_marks': totalMarks,
      'passing_marks': passingMarks,
      'negative_marking_factor': negativeMarkingFactor,
      'randomize_questions': randomizeQuestions ? 1 : 0,
      'randomize_options': randomizeOptions ? 1 : 0,
      'anti_cheating_enabled': antiCheatingEnabled ? 1 : 0,
      'is_published': isPublished ? 1 : 0,
      'qr_code_token': qrCodeToken,
      'subject_name': subjectName,
      'teacher_name': teacherName,
      'attempt_status': attemptStatus,
      'score': score,
    };
  }

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
  bool get isEnded => endTime.isBefore(DateTime.now());
}
