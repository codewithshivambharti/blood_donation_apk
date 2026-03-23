class Validators {
  static String? required(String val, String name) {
    if (val.isEmpty) return '* $name is required';
    return null; // ✅
  }

  static String? email(String val) {
    if (!val.contains('@')) return '* Please enter a valid email';
    return null; // ✅
  }

  static String? phone(String val) {
    final regExp = RegExp(r'(^[0-9]{10}$)');
    if (!regExp.hasMatch(val)) return '* Please enter a valid phone number';
    return null; // ✅
  }

  static String? birthYear(String val) {
    final regExp = RegExp(r'^(19|20)\d{2}$');
    if (!regExp.hasMatch(val)) return '* Please enter a valid year';

    final year = int.tryParse(val) ?? 0;
    final age = DateTime.now().year - year;

    if (age < 18) return '* You must be at least 18 years old';
    if (age > 100) return '* You must be less than 100 years old';
    return null; // ✅
  }

  static String? name(String val) {
    final regExp = RegExp(r"^[a-zA-Z]+(([' -][a-zA-Z ])?[a-zA-Z]*)*$");
    if (!regExp.hasMatch(val)) return '* Please enter a valid name';
    return null; // ✅
  }
}