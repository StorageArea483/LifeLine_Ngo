import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> addUserDetails({
  String? docId,
  String? ngoName,
  String? ngoLogo,
  String? registrationNumber,
  String? address,
  String? branchName,
  String? phone,
  String? email,
  String? password,
  String? directorName,
  String? projectManager,
  String? geographicalCoverage,
  String? pastExperience,
  String? selectedProgram,
  String? documentUrl,
}) async {
  final data = {
    'ngoName': ngoName,
    'ngoLogo': ngoLogo,
    'registrationNumber': registrationNumber,
    'address': address,
    'branchName': branchName,
    'phone': phone,
    'email': email,
    'password': password,
    'directorName': directorName,
    'projectManager': projectManager,
    'geographicalCoverage': geographicalCoverage,
    'pastExperience': pastExperience,
    'selectedProgram': selectedProgram,
    'documentUrl': documentUrl,
    'approved': false,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // If docId exists, update the existing document
  if (docId != null) {
    await FirebaseFirestore.instance
        .collection('ngo-info-database')
        .doc(docId)
        .update(data);
    return docId;
  }

  // Otherwise create a new document
  final docRef = await FirebaseFirestore.instance
      .collection('ngo-info-database')
      .add(data);
  return docRef.id;
}
