import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String _endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String _projectId = '69f17cf0002d719084cd';
  static const String _bucketId = '69f180590004b2f6de27';

  late final Client _client;
  late final Storage _storage;

  AppwriteService() {
    _client = Client().setEndpoint(_endpoint).setProject(_projectId);
    _storage = Storage(_client);
  }

  Future<String> uploadDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String ngoName,
    required String branchNumber,
  }) async {
    final storageFileName = '${ngoName}_${branchNumber}_$fileName';

    // Generate unique file ID
    final fileId = ID.unique();

    // Upload file to Appwrite Storage
    await _storage.createFile(
      bucketId: _bucketId,
      fileId: fileId,
      file: InputFile.fromBytes(bytes: fileBytes, filename: storageFileName),
    );

    // Construct and return the public view URL
    final downloadUrl =
        '$_endpoint/storage/buckets/$_bucketId/files/$fileId/view?project=$_projectId';
    return downloadUrl;
  }
}
