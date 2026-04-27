import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:life_line_ngo/model/dropped_file.dart';
import 'package:life_line_ngo/styles/styles.dart';

class UploadNgoFile extends StatefulWidget {
  final Function(Uint8List? bytes, String? fileName, String? mimeType)?
  onFileSelected;

  const UploadNgoFile({super.key, this.onFileSelected});

  @override
  State<UploadNgoFile> createState() => _UploadNgoFileState();
}

class _UploadNgoFileState extends State<UploadNgoFile> {
  DropzoneViewController? controller;
  DroppedFile? droppedFile;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview box - shows only when file is selected
        if (droppedFile != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.9),
              borderRadius: AppDecorations.textFieldBorderRadius,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Row(
              children: [
                // Image preview or file icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: droppedFile!.mime.startsWith('image/')
                      ? Image.network(
                          droppedFile!.url,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: AppColors.surfaceLight.withValues(alpha: 0.5),
                          child: const Icon(
                            Icons.insert_drive_file,
                            size: 26,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        droppedFile!.name,
                        style: AppText.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        droppedFile!.size,
                        style: AppText.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Remove button
                IconButton(
                  onPressed: _removeFile,
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        // Upload dropzone
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: AppDecorations.textFieldBorderRadius,
            border: Border.all(color: AppColors.borderColor, width: 2),
          ),
          child: Stack(
            children: [
              DropzoneView(
                onDropFile: _acceptFile,
                onCreated: (ctrl) => controller = ctrl,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        size: 36,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _pickFile,
                          child: Text(
                            'Upload a file or drag and drop',
                            style: AppText.small.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scanned certificates, project reports, financials etc.',
                        style: AppText.small.copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    if (_isDisposed || controller == null) return;
    try {
      final files = await controller!.pickFiles();
      if (files.isEmpty || _isDisposed) return;
      _acceptFile(files.first);
    } catch (e) {
      // Ignore errors if widget is disposed
    }
  }

  Future<void> _acceptFile(dynamic event) async {
    if (_isDisposed || controller == null) return;
    try {
      final name = event.name;
      final mime = await controller!.getFileMIME(event);
      final bytes = await controller!.getFileSize(event);
      final url = await controller!.createFileUrl(event);
      final fileData = await controller!.getFileData(event);

      if (_isDisposed || !mounted) return;

      setState(() {
        droppedFile = DroppedFile(
          url: url,
          name: name,
          mime: mime,
          bytes: bytes,
        );
      });

      // Pass file data to parent
      widget.onFileSelected?.call(fileData, name, mime);
    } catch (e) {
      // Ignore errors if widget is disposed
    }
  }

  void _removeFile() {
    if (_isDisposed || !mounted) return;
    setState(() {
      droppedFile = null;
    });
    widget.onFileSelected?.call(null, null, null);
  }
}
