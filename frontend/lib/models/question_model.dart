class QuestionModel {
  final int id;
  final int examId;
  final String questionText;
  final String questionType; // 'mcq', 'tf'
  final double marks;
  final double negativeMarks;
  final String? attachmentUrl;
  final List<OptionModel> options;
  int? selectedOptionId; // Local student response tracker

  QuestionModel({
    required this.id,
    required this.examId,
    required this.questionText,
    required this.questionType,
    required this.marks,
    required this.negativeMarks,
    this.attachmentUrl,
    required this.options,
    this.selectedOptionId,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    var optsList = json['options'] as List? ?? [];
    List<OptionModel> parsedOptions = optsList.map((o) => OptionModel.fromJson(o)).toList();

    return QuestionModel(
      id: int.parse(json['id'].toString()),
      examId: int.parse(json['exam_id'].toString()),
      questionText: json['question_text'] as String,
      questionType: json['question_type'] as String? ?? 'mcq',
      marks: double.parse(json['marks']?.toString() ?? '1.00'),
      negativeMarks: double.parse(json['negative_marks']?.toString() ?? '0.00'),
      attachmentUrl: json['attachment_url'] as String?,
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'question_text': questionText,
      'question_type': questionType,
      'marks': marks,
      'negative_marks': negativeMarks,
      'attachment_url': attachmentUrl,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class OptionModel {
  final int id;
  final String optionText;
  final bool isCorrect;

  OptionModel({
    required this.id,
    required this.optionText,
    required this.isCorrect,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: int.parse(json['id'].toString()),
      optionText: json['option_text'] as String,
      isCorrect: json['is_correct'].toString() == '1' || json['is_correct'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_text': optionText,
      'is_correct': isCorrect ? 1 : 0,
    };
  }
}
