// ignore: camel_case_types
class mdsUser {
  final String uid; // Firebase Unique User Identifier
  final String email; // User's Email Address
  final String name; // User's Name
  final bool isPremium; // If user is a premium subscriber?

  // Add more fields as needed... Then add them to the constructor below

  // mdsUser Constructor
  mdsUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.isPremium,
  });
}
