class ChatModerationResult {
  final bool allowed;
  final String? warning;

  const ChatModerationResult._({required this.allowed, this.warning});

  const ChatModerationResult.allowed() : this._(allowed: true);

  const ChatModerationResult.blocked(String warning)
    : this._(allowed: false, warning: warning);
}

class ChatModerationService {
  static final RegExp _phonePattern = RegExp(
    r'(\+?\d[\d\s().-]{7,}\d)',
    caseSensitive: false,
  );
  static final RegExp _emailPattern = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _linkPattern = RegExp(
    r'((https?:\/\/|www\.)\S+|\b[a-z0-9-]+\.(com|net|org|io|ma|app|dev|co)\b)',
    caseSensitive: false,
  );
  static final RegExp _externalAppPattern = RegExp(
    r'\b(whatsapp|telegram|signal|instagram|facebook|snapchat|gmail|email me|call me|text me)\b',
    caseSensitive: false,
  );
  static final RegExp _repeatedSpamPattern = RegExp(r'(.)\1{9,}');

  static ChatModerationResult validateLimitedMessage(String text) {
    final value = text.trim();
    if (value.isEmpty) {
      return const ChatModerationResult.blocked('Message cannot be empty.');
    }
    if (value.length > 500) {
      return const ChatModerationResult.blocked(
        'Keep pre-booking messages under 500 characters.',
      );
    }
    if (_emailPattern.hasMatch(value)) {
      return const ChatModerationResult.blocked(
        'Email sharing unlocks after a booking is created.',
      );
    }
    if (_linkPattern.hasMatch(value)) {
      return const ChatModerationResult.blocked(
        'External links are blocked until booking is confirmed.',
      );
    }
    if (_phonePattern.hasMatch(value)) {
      return const ChatModerationResult.blocked(
        'Phone numbers are blocked until booking is confirmed.',
      );
    }
    if (_externalAppPattern.hasMatch(value)) {
      return const ChatModerationResult.blocked(
        'External contact apps are blocked until booking is confirmed.',
      );
    }
    if (_repeatedSpamPattern.hasMatch(value) || value.split(' ').length > 90) {
      return const ChatModerationResult.blocked(
        'This looks like spam. Please send a shorter service question.',
      );
    }
    return const ChatModerationResult.allowed();
  }
}
