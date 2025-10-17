class User {
  final String id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromFirestore(Map<String, dynamic> data) {
    return User(id: data['id'] ?? '', email: data['email'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email};
  }
}
