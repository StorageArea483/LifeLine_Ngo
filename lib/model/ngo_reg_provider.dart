import 'dart:typed_data';

import 'package:flutter_riverpod/legacy.dart';
import 'package:life_line_ngo/widgets/ngo_file_size.dart';

class NgoRegNotifier extends StateNotifier<NgoRegState> {
  NgoRegNotifier()
    : super(
        const NgoRegState(
          selectedProgram: '',
          fileBytes: null,
          fileName: null,
          isLoading: false,
          droppedFile: null,
        ),
      );

  void setSelectedProgram(String program) {
    state = state.copyWith(selectedProgram: program);
  }

  void setFileBytes(Uint8List? fileBytes) {
    state = state.copyWith(fileBytes: fileBytes);
  }

  void setFileName(String? fileName) {
    state = state.copyWith(fileName: fileName);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setDroppedFile(DroppedFile? droppedFile) {
    state = state.copyWith(droppedFile: droppedFile);
  }
}

class NgoRegState {
  final String selectedProgram;
  final Uint8List? fileBytes;
  final String? fileName;
  final bool isLoading;
  final DroppedFile? droppedFile;

  const NgoRegState({
    this.selectedProgram = '',
    this.fileBytes,
    this.fileName,
    this.isLoading = false,
    this.droppedFile,
  });

  NgoRegState copyWith({
    String? selectedProgram,
    Uint8List? fileBytes,
    String? fileName,
    bool? isLoading,
    DroppedFile? droppedFile,
  }) {
    return NgoRegState(
      selectedProgram: selectedProgram ?? this.selectedProgram,
      fileBytes: fileBytes ?? this.fileBytes,
      fileName: fileName ?? this.fileName,
      isLoading: isLoading ?? this.isLoading,
      droppedFile: droppedFile ?? this.droppedFile,
    );
  }
}

final ngoRegProvider =
    StateNotifierProvider.autoDispose<NgoRegNotifier, NgoRegState>(
      (ref) => NgoRegNotifier(),
    );
