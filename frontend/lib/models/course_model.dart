class CourseModel {
  final int id;
  final String name;
  final String code;
  final String? description;

  CourseModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
    };
  }
}
