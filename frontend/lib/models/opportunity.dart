class Opportunity {
  final String title;
  final String type;
  final String country;
  final String field;
  final String educationLevel;
  final String deadline;
  final String description;
  final String applicationLink;

  const Opportunity({
    required this.title,
    required this.type,
    this.country = '',
    this.field = '',
    this.educationLevel = '',
    this.deadline = '',
    this.description = '',
    this.applicationLink = '',
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      title: (json['title'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      field: (json['field'] as String?) ?? '',
      educationLevel: (json['educationLevel'] as String?) ?? '',
      deadline: (json['deadline'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      applicationLink: (json['applicationLink'] as String?) ?? '',
    );
  }
}
