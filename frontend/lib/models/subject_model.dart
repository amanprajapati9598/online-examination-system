class SubjectModel {
  final int id;
  final int courseId;
  final String name;
  final String code;
  final String? description;
  final String? courseName;

  SubjectModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.code,
    this.description,
    this.courseName,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: int.parse(json['id'].toString()),
      courseId: int.parse(json['course_id'].toString()),
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      courseName: json['course_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'code': code,
      'description': description,
      'course_name': courseName,
    };
  }
}
