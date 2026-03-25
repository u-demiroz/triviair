import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionTranslation {
  final String question;
  final List<String> options;

  const QuestionTranslation({
    required this.question,
    required this.options,
  });

  factory QuestionTranslation.fromMap(Map<String, dynamic> map) {
    return QuestionTranslation(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
    );
  }
}

class QuestionModel {
  final String id;
  final String category;
  final String type; // 'text' | 'image'
  final String? imageUrl;
  final int correctAnswerIndex;
  final String difficulty; // 'easy' | 'medium' | 'hard'
  final Map<String, QuestionTranslation> translations;
  final DateTime? createdAt;

  const QuestionModel({
    required this.id,
    required this.category,
    required this.type,
    this.imageUrl,
    required this.correctAnswerIndex,
    required this.difficulty,
    required this.translations,
    this.createdAt,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final translationsMap = data['translations'] as Map<String, dynamic>? ?? {};

    return QuestionModel(
      id: doc.id,
      category: data['category'] ?? '',
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
      difficulty: data['difficulty'] ?? 'medium',
      translations: translationsMap.map(
        (key, value) => MapEntry(
          key,
          QuestionTranslation.fromMap(value as Map<String, dynamic>),
        ),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  QuestionTranslation getTranslation(String languageCode) {
    return translations[languageCode] ?? translations['en'] ?? translations.values.first;
  }

  String getQuestion(String languageCode) => getTranslation(languageCode).question;
  List<String> getOptions(String languageCode) => getTranslation(languageCode).options;
}
