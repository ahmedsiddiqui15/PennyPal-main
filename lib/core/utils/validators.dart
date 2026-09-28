

class Validators {
  Validators._();

  static final RegExp _email =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[A-Za-z]{2,}$');
  static final RegExp _phone = RegExp(r'^[+]?[\d\s\-()]{7,20}$');
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'\d');

  
  
  
  static final RegExp _name =
      RegExp(r"^[\p{L}][\p{L} .'\-]*$", unicode: true);

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (value.contains(' ')) return 'Password cannot contain spaces';
    if (!_hasLetter.hasMatch(value)) return 'Include at least one letter';
    if (!_hasDigit.hasMatch(value)) return 'Include at least one number';
    return null;
  }

  
  
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  
  static double passwordStrength(String value) {
    if (value.isEmpty) return 0;
    double score = 0;
    if (value.length >= 8) score += 0.35;
    if (value.length >= 12) score += 0.15;
    if (_hasLetter.hasMatch(value)) score += 0.2;
    if (_hasDigit.hasMatch(value)) score += 0.2;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score += 0.1;
    return score.clamp(0, 1).toDouble();
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  
  static String? name(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Full name is required';
    if (_hasDigit.hasMatch(trimmed)) return 'Name cannot contain numbers';
    if (trimmed.length < 3) return 'Name is too short';
    if (!_name.hasMatch(trimmed)) return 'Name can only contain letters';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    if (!_phone.hasMatch(value.trim())) return 'Enter a valid mobile number';
    return null;
  }

  
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid amount';
    if (parsed <= 0) return 'Amount must be greater than zero';
    return null;
  }

  static String? notEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }
}
