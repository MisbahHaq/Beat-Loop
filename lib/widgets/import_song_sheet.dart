import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../Services/catalog_service.dart';
import '../Services/cloudinary_service.dart';
import '../Services/link_import_service.dart';
import '../theme.dart';

enum _Stage { entry, results, working, form, done }

class ImportSongSheet extends StatefulWidget {
  final VoidCallback onImported;
  const ImportSongSheet({super.key, required this.onImported});

  @override
  State<ImportSongSheet> createState() => _ImportSongSheetState();
}

class _ImportSongSheetState extends State<ImportSongSheet> {
  final LinkImportService _service = LinkImportService();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  _Stage _stage = _Stage.entry;
  String _stageText = '';
  double? _progress;
  String? _error;
  CancelToken? _cancelToken;

  ResolvedLink? _resolved;
  List<Video> _results = [];
  String? _targetVideoUrl;
  String? _thumbnailUrl;
  File? _pickedImage;

  bool _saving = false;

  @override
  void dispose() {
    _cancelToken?.cancel();
    _linkController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  void _setStageText(String text, [double? progress]) {
    if (!mounted) return;
    setState(() {
      _stageText = text;
      if (progress != null) _progress = progress;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _linkController.text = text;
        _error = null;
      });
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _error = null;
      _stage = _Stage.working;
      _stageText = 'Fetching info…';
      _progress = null;
    });
    try {
      final resolved = await _service.resolve(_linkController.text);
      if (!mounted) return;
      setState(() => _resolved = resolved);

      if (resolved.needsSearch) {
        _setStageText('Searching on YouTube…');
        final artist = resolved.artist.trim();
        final query = artist.isEmpty || artist.toLowerCase() == 'unknown artist'
            ? resolved.title
            : '${resolved.title} $artist';
        final results = await _service.search(query);
        if (!mounted) return;
        if (results.isEmpty) {
          throw Exception('No matching YouTube track found');
        }
        setState(() {
          _results = results;
          _stage = _Stage.results;
        });
        return;
      }

      _targetVideoUrl = resolved.sourceUrl;
      _thumbnailUrl = resolved.thumbnailUrl;
      await _downloadAndUpload();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.entry;
        _progress = null;
        _error = _messageOf(e);
      });
    }
  }

  Future<void> _pickResult(Video video) async {
    _targetVideoUrl = 'https://www.youtube.com/watch?v=${video.id.value}';
    _thumbnailUrl = video.thumbnails.maxResUrl;
    await _downloadAndUpload();
  }

  Future<void> _downloadAndUpload() async {
    final resolved = _resolved;
    final target = _targetVideoUrl;
    if (resolved == null || target == null) return;

    setState(() {
      _stage = _Stage.working;
      _stageText = 'Fetching stream info…';
      _progress = null;
      _cancelToken = CancelToken();
    });
    debugPrint('[import] starting download+upload for $target');
    try {
      final bytes = await _service.downloadAudio(
        videoIdOrUrl: target,
        onPhase: (phase) {
          debugPrint('[import] ui phase: $phase');
          _setStageText(phase);
        },
        onProgress: (p) => _setStageText('Downloading audio…', p),
      );
      if (!mounted) return;

      debugPrint('[import] upload to cloud starting (${bytes.length} bytes)');
      _setStageText('Uploading to the cloud…', 0);
      final audioUrl = await CloudinaryService.uploadBytes(
        bytes: bytes,
        filename: _service.audioFileName(resolved.title),
        resourceType: 'video',
        onProgress: (p) => _setStageText('Uploading to the cloud…', p),
      );
      debugPrint('[import] cloud audio upload done: $audioUrl');
      if (!mounted) return;
      _audioUrl = audioUrl;

      setState(() {
        _titleController.text = resolved.title;
        _artistController.text =
            resolved.artist.isEmpty ? 'Unknown artist' : resolved.artist;
        _stage = _Stage.form;
        _progress = null;
      });
    } catch (e, st) {
      debugPrint('[import] download/upload FAILED: ${e.runtimeType}: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _stage = _Stage.entry;
        _progress = null;
        _error = _messageOf(e);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;
      setState(() {
        _pickedImage = File(picked.path);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = "Couldn't open the gallery");
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give the song a name');
      return;
    }
    if (_audioUrl == null || _audioUrl!.isEmpty) {
      setState(() => _error = 'Audio upload is missing — start over');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _stage = _Stage.working;
      _stageText = 'Saving artwork…';
      _progress = 0;
    });

    try {
      String imageUrl = '';
      if (_pickedImage != null) {
        _setStageText('Uploading artwork…', 0);
        imageUrl = await CloudinaryService.uploadFile(
          file: _pickedImage!,
          resourceType: 'image',
          onProgress: (p) => _setStageText('Uploading artwork…', p),
        );
      } else if (_thumbnailUrl != null && _thumbnailUrl!.startsWith('http')) {
        _setStageText('Uploading artwork…', 0);
        final thumbBytes = await _service.fetchBytes(_thumbnailUrl!);
        if (!mounted) return;
        imageUrl = await CloudinaryService.uploadBytes(
          bytes: thumbBytes,
          filename: 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
          resourceType: 'image',
          onProgress: (p) => _setStageText('Uploading artwork…', p),
        );
      }

      await CatalogService.addSong(
        path: _audioUrl!,
        title: title,
        image: imageUrl.isEmpty ? 'assets/images/0016.jpg' : imageUrl,
        artist: artist.isEmpty ? 'Unknown artist' : artist,
        sourceUrl: _resolved?.sourceUrl,
      );
      if (!mounted) return;

      widget.onImported();
      setState(() => _stage = _Stage.done);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.form;
        _progress = null;
        _error = _messageOf(e);
      });
    } finally {
      _saving = false;
    }
  }

  String? _audioUrl;

  String _messageOf(Object e) {
    if (e is RequestLimitExceededException) {
      return 'YouTube is rate-limiting this network — wait a few minutes and try again';
    }
    if (e is TimeoutException) {
      return 'Took too long — check your connection and try again';
    }
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        return data['error']['message']?.toString() ?? 'Upload failed';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Network timed out — try again';
      }
      return 'Network error — check your connection';
    }
    final msg = e.toString().replaceFirst('Exception: ', '');
    return msg.isEmpty ? 'Something went wrong' : msg;
  }

  String _fmtDuration(Duration? d) {
    if (d == null) return '';
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cream,
        border: Border(top: BorderSide(color: AppTheme.ink, width: 4)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              ...switch (_stage) {
                _Stage.entry => _buildEntry(),
                _Stage.results => _buildResults(),
                _Stage.working => _buildWorking(),
                _Stage.form => _buildForm(),
                _Stage.done => _buildDone(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text('Import a song', style: AppTheme.headingMd),
        ),
        if (_stage != _Stage.done)
          GestureDetector(
            onTap: () {
              _cancelToken?.cancel();
              if (mounted) Navigator.of(context).maybePop();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.hotPink,
                border: Border.all(color: AppTheme.ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                ],
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildEntry() {
    return [
      Text(
        'paste a YouTube or Spotify song link',
        style: AppTheme.hand.copyWith(color: AppTheme.dimText),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.paperWhite,
          border: Border.all(color: AppTheme.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.ink, offset: Offset(3, 3)),
          ],
        ),
        child: TextField(
          controller: _linkController,
          style: AppTheme.body,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _fetch(),
          decoration: InputDecoration(
            hintText: 'YouTube or Spotify link…',
            hintStyle: AppTheme.monoSm,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffixIcon: IconButton(
              tooltip: 'Paste',
              icon: const Icon(Icons.content_paste, color: AppTheme.ink),
              onPressed: _paste,
            ),
          ),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 10),
        _errorBox(_error!),
      ],
      const SizedBox(height: 16),
      _bigButton(
        label: 'FETCH IT',
        color: AppTheme.cyberYellow,
        icon: Icons.download_for_offline_outlined,
        onTap: _fetch,
      ),
      const SizedBox(height: 10),
      Center(
        child: Text(
          'audio is saved to your cloud — even if the video disappears',
          style: AppTheme.monoSm,
        ),
      ),
    ];
  }

  List<Widget> _buildResults() {
    final resolved = _resolved;
    return [
      Text('which track is it?', style: AppTheme.handLg),
      const SizedBox(height: 4),
      Text(
        'matched “${resolved?.title ?? ''}” on YouTube',
        style: AppTheme.monoSm,
      ),
      const SizedBox(height: 12),
      ..._results.take(5).map(
            (video) => GestureDetector(
              onTap: () => _pickResult(video),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.paperWhite,
                  border: Border.all(color: AppTheme.ink, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.ink, width: 2),
                        image: DecorationImage(
                          image:
                              NetworkImage(video.thumbnails.mediumResUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: AppTheme.bodyBold.copyWith(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${video.author}  ·  ${_fmtDuration(video.duration)}',
                            style: AppTheme.monoSm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.ink),
                  ],
                ),
              ),
            ),
          ),
    ];
  }

  List<Widget> _buildWorking() {
    return [
      const SizedBox(height: 8),
      Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_stageText, style: AppTheme.bodyBold),
          ),
          if (_progress != null)
            Text(
              '${(_progress! * 100).round()}%',
              style: AppTheme.monoAccent,
            ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        height: 14,
        decoration: BoxDecoration(
          color: AppTheme.warmCream,
          border: Border.all(color: AppTheme.ink, width: 2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _progress ?? 0.15,
          child: Container(color: AppTheme.electricCyan),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'hang tight — downloading & uploading',
          style: AppTheme.hand.copyWith(color: AppTheme.dimText),
        ),
      ),
    ];
  }

  List<Widget> _buildForm() {
    return [
      Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.ink, width: 3),
              boxShadow: const [
                BoxShadow(color: AppTheme.ink, offset: Offset(3, 3)),
              ],
              image: _pickedImage != null
                  ? DecorationImage(
                      image: FileImage(_pickedImage!),
                      fit: BoxFit.cover,
                    )
                  : (_thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null),
              color: AppTheme.softLavender,
            ),
            child: _pickedImage == null && _thumbnailUrl == null
                ? const Icon(Icons.music_note, color: AppTheme.ink, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('cover art', style: AppTheme.monoAccent),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.softCyan,
                      border: Border.all(color: AppTheme.ink, width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppTheme.ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Text(
                      _pickedImage == null
                          ? 'PICK FROM GALLERY'
                          : 'CHANGE IMAGE',
                      style: AppTheme.monoAccent.copyWith(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _fieldLabel('SONG NAME'),
      _textField(_titleController, 'song title'),
      const SizedBox(height: 12),
      _fieldLabel('ARTIST'),
      _textField(_artistController, 'artist name'),
      if (_error != null) ...[
        const SizedBox(height: 10),
        _errorBox(_error!),
      ],
      const SizedBox(height: 18),
      _bigButton(
        label: 'SAVE TO CLOUD',
        color: AppTheme.hotPink,
        textColor: Colors.white,
        icon: Icons.cloud_upload,
        onTap: _saving ? null : _save,
      ),
    ];
  }

  List<Widget> _buildDone() {
    return [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.mutedGreen,
          border: Border.all(color: AppTheme.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.ink, offset: Offset(3, 3)),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 40, color: AppTheme.ink),
            const SizedBox(height: 8),
            Text('it’s in your library!', style: AppTheme.handLg),
            const SizedBox(height: 4),
            Text(
              'saved to the cloud — play it anytime, even offline',
              style: AppTheme.monoSm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _bigButton(
        label: 'DONE',
        color: AppTheme.cyberYellow,
        icon: Icons.check,
        onTap: () => Navigator.of(context).maybePop(),
      ),
    ];
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTheme.monoAccent),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paperWhite,
        border: Border.all(color: AppTheme.ink, width: 2),
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.body,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.monoSm,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.softPink,
        border: Border.all(color: AppTheme.ink, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppTheme.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTheme.body.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _bigButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
    IconData? icon,
    Color textColor = AppTheme.ink,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: AppTheme.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: AppTheme.ink, offset: Offset(3, 3)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTheme.monoAccent.copyWith(
                  color: textColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
