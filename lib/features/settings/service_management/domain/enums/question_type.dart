// lib/features/settings/service_management/domain/enums/question_type.dart

/// The type of a dynamic form question, configured by the admin and
/// rendered by the user-facing service form (features/services).
enum QuestionType {
  shortAnswer,
  paragraph,
  multipleChoice,
  checkboxes,
  dropdown,
  date,
  time,
  fileUpload,
}

extension QuestionTypeX on QuestionType {
  /// Value stored/sent to the PHP backend.
  String get apiValue {
    switch (this) {
      case QuestionType.shortAnswer:
        return 'short_answer';
      case QuestionType.paragraph:
        return 'paragraph';
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.checkboxes:
        return 'checkboxes';
      case QuestionType.dropdown:
        return 'dropdown';
      case QuestionType.date:
        return 'date';
      case QuestionType.time:
        return 'time';
      case QuestionType.fileUpload:
        return 'file_upload';
    }
  }

  /// Label shown in the "Select Question Type" picker + question cards.
  String get label {
    switch (this) {
      case QuestionType.shortAnswer:
        return 'Short answer';
      case QuestionType.paragraph:
        return 'Paragraph';
      case QuestionType.multipleChoice:
        return 'Multiple choice';
      case QuestionType.checkboxes:
        return 'Checkboxes';
      case QuestionType.dropdown:
        return 'Dropdown';
      case QuestionType.date:
        return 'Date';
      case QuestionType.time:
        return 'Time';
      case QuestionType.fileUpload:
        return 'File upload';
    }
  }

  /// Whether this question type needs an editable list of options
  /// (multiple choice / checkboxes / dropdown).
  bool get hasOptions =>
      this == QuestionType.multipleChoice ||
      this == QuestionType.checkboxes ||
      this == QuestionType.dropdown;

  static QuestionType fromApiValue(String? value) {
    switch (value) {
      case 'paragraph':
        return QuestionType.paragraph;
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'checkboxes':
        return QuestionType.checkboxes;
      case 'dropdown':
        return QuestionType.dropdown;
      case 'date':
        return QuestionType.date;
      case 'time':
        return QuestionType.time;
      case 'file_upload':
        return QuestionType.fileUpload;
      case 'short_answer':
      default:
        return QuestionType.shortAnswer;
    }
  }
}
