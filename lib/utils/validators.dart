/// Shared input validation for forms (signup, login, etc.).

/// RFC 5322–style email regex (simplified but catches most invalid emails).
final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
);

/// Returns an error message if [value] is not a valid email, otherwise null.
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Please enter your email';
  if (!_emailRegex.hasMatch(trimmed)) {
    return 'Please enter a valid email address';
  }
  return null;
}

/// Returns an error message if [value] is empty or too short for a name.
String? validateRequiredName(String? value, {String fieldName = 'Name'}) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter $fieldName';
  }
  if (value.trim().length < 2) {
    return '$fieldName must be at least 2 characters';
  }
  return null;
}

/// Returns an error message if [value] is empty.
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter $fieldName';
  }
  return null;
}

/// Returns an error message if [value] is not a valid password (min length 6).
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a password';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

/// Returns an error message if [confirm] does not match [password].
String? validateConfirmPassword(String? confirm, String password) {
  if (confirm == null || confirm.isEmpty) {
    return 'Please confirm your password';
  }
  if (confirm != password) {
    return 'Passwords do not match';
  }
  return null;
}

/// Optional phone: if provided, allow only digits, spaces, +, -, (), and reasonable length.
String? validatePhoneOptional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  if (cleaned.length > 0 && !RegExp(r'^\d+$').hasMatch(cleaned)) {
    return 'Please enter a valid phone number';
  }
  if (cleaned.length > 15) {
    return 'Phone number is too long';
  }
  return null;
}
