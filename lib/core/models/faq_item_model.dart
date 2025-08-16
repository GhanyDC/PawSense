class FAQItemModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int views;
  final int helpfulVotes;
  final bool isExpanded;

  FAQItemModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.views,
    required this.helpfulVotes,
    this.isExpanded = false,
  });

  FAQItemModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    int? views,
    int? helpfulVotes,
    bool? isExpanded,
  }) {
    return FAQItemModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      views: views ?? this.views,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}