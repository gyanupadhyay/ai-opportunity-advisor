import '../constants.dart';

class Opportunity {
  final String id;
  final String title;
  final String type;
  final String country;
  final String field;
  final String educationLevel;
  final String deadline;
  final String description;
  final String applicationLink;
  final String source;

  const Opportunity({
    this.id = '',
    required this.title,
    required this.type,
    this.country = '',
    this.field = '',
    this.educationLevel = '',
    this.deadline = '',
    this.description = '',
    this.applicationLink = '',
    this.source = sourceManual,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      field: (json['field'] as String?) ?? '',
      educationLevel: (json['educationLevel'] as String?) ?? '',
      deadline: (json['deadline'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      applicationLink: (json['applicationLink'] as String?) ?? '',
      source: (json['source'] as String?) ?? sourceManual,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'country': country,
        'field': field,
        'educationLevel': educationLevel,
        'deadline': deadline,
        'description': description,
        'applicationLink': applicationLink,
      };
}
