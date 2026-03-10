bool isEmailValid(String email) {
  return RegExp(r'^\\S+@\\S+\\.\\S+\$').hasMatch(email);
}
