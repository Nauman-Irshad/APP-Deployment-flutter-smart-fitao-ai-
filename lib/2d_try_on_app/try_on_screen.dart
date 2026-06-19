import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'captured_photo_session.dart';
import 'try_on_api_client.dart';
import 'try_on_config.dart';
import 'try_on_download.dart';
import 'try_on_find_tailor_screen.dart';
import 'try_on_fitting_flow_header.dart';
import 'try_on_image_prep.dart';
import 'try_on_order_session.dart';
import 'try_on_garment_service.dart';
import 'try_on_theme.dart';

/// Full-screen 2D try-on — UI mirrors [id-2d-try-on/src/App.tsx] pipeline layout.
class TryOn2dScreen extends StatefulWidget {
  const TryOn2dScreen({
    super.key,
    this.initialPersonImageUrl,
    this.initialPersonBytes,
    this.landmarkCount = 0,
    this.embeddedInNav = false,
  });

  final String? initialPersonImageUrl;
  final Uint8List? initialPersonBytes;
  final int landmarkCount;

  /// True when shown as a bottom-nav tab on marketplace (no back button).
  final bool embeddedInNav;

  static Future<void> open(
    BuildContext context, {
    String? personImageUrl,
    int landmarkCount = 0,
  }) {
    final url = personImageUrl ?? CapturedPhotoSession.imageUrl;
    final lm = landmarkCount > 0 ? landmarkCount : CapturedPhotoSession.landmarkCount;
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TryOn2dScreen(
          initialPersonImageUrl: url,
          landmarkCount: lm,
        ),
      ),
    );
  }

  @override
  State<TryOn2dScreen> createState() => _TryOn2dScreenState();
}

/// Embedded wizard panel — opens full [TryOn2dScreen].
class TryOn2dPanel extends StatelessWidget {
  const TryOn2dPanel({
    super.key,
    this.personImageUrl,
    this.landmarkCount = 0,
    this.onBack,
    this.onContinue,
  });

  final String? personImageUrl;
  final int landmarkCount;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '2D Shalwar Kameez Try On',
          style: TryOnTheme.heading(size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          'Same experience as the website — upload photo, pick kurta, run AI try-on.',
          style: TryOnTheme.body(size: 13, color: TryOnTheme.brownMuted),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => TryOn2dScreen.open(
              context,
              personImageUrl: personImageUrl,
              landmarkCount: landmarkCount,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TryOnTheme.brown,
              foregroundColor: TryOnTheme.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Open 2D Try-On Studio',
              style: TryOnTheme.body(size: 15, weight: FontWeight.w600, color: TryOnTheme.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(onPressed: onBack, child: const Text('Back')),
              ),
            if (onBack != null && onContinue != null) const SizedBox(width: 12),
            if (onContinue != null)
              Expanded(
                child: OutlinedButton(onPressed: onContinue, child: const Text('Find tailor & chat')),
              ),
          ],
        ),
      ],
    );
  }
}

class _TryOn2dScreenState extends State<TryOn2dScreen> {
  final _api = TryOnApiClient();
  final _picker = ImagePicker();

  List<String> _garments = [];
  final Set<String> _brokenGarments = {};
  String? _selectedGarment;
  Uint8List? _personBytes;
  bool _loadingGarments = true;
  bool _loadingPerson = false;
  bool _runningTryOn = false;
  int _progress = 0;
  String _progressLabel = '';
  String? _error;
  String? _userImageError;
  String? _garmentPreviewError;
  String? _resultImageError;
  Uint8List? _resultBytes;
  Timer? _progressTimer;
  String _apiModeLabel = 'AI POWERED';

  static const _progressLabels = <(int, String)>[
    (12, 'Preparing images…'),
    (28, 'Sending to Hugging Face IDM-VTON…'),
    (45, 'AI fitting kurta on your photo…'),
    (65, 'Generating try-on (~30 sec on HF)…'),
    (82, 'Almost done…'),
    (95, 'Finishing…'),
    (100, 'Try-on complete!'),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant TryOn2dScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPersonImageUrl != widget.initialPersonImageUrl &&
        widget.initialPersonImageUrl != null &&
        widget.initialPersonImageUrl!.isNotEmpty) {
      _loadPersonFromUrl(widget.initialPersonImageUrl!);
    }
    if (oldWidget.initialPersonBytes != widget.initialPersonBytes &&
        widget.initialPersonBytes != null &&
        widget.initialPersonBytes!.isNotEmpty) {
      _applyPersonBytes(widget.initialPersonBytes!);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _api.dispose();
    super.dispose();
  }

  String _labelForProgress(int p) {
    for (final row in _progressLabels) {
      if (p <= row.$1) return row.$2;
    }
    return _progressLabels.last.$2;
  }

  Future<void> _bootstrap() async {
    String? apiWarning;
    try {
      final health = await _api.fetchHealth();
      if (!health.ok) {
        apiWarning = health.message;
      } else if (mounted) {
        setState(() => _apiModeLabel = health.etaLabel.toUpperCase());
      }
    } catch (_) {
      apiWarning =
          'Try-on API warming up (${TryOnConfig.apiBase}). Tap Run Try-On to retry.';
    }

    try {
      final names = await TryOnGarmentService.loadGarmentNames();
      if (!mounted) return;
      final pref = TryOnOrderSession.instance.tryOnGarmentFile;
      setState(() {
        _garments = names;
        _selectedGarment = names.isNotEmpty
            ? (pref.isNotEmpty && names.contains(pref) ? pref : names.first)
            : null;
        _loadingGarments = false;
        if (names.isEmpty) {
          _error = 'No kurta images found. Sync assets/2d_try_on_garments.';
        }
      });
      unawaited(TryOnGarmentService.preloadGarments(names));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGarments = false;
        _error = 'Could not load outfit gallery: $e';
      });
    }
    final bytes = widget.initialPersonBytes;
    if (bytes != null && bytes.isNotEmpty) {
      if (mounted) _applyPersonBytes(bytes);
      return;
    }
    final url = widget.initialPersonImageUrl;
    if (url != null && url.isNotEmpty) await _loadPersonFromUrl(url);
  }

  void _applyPersonBytes(List<int> raw) {
    setState(() {
      _personBytes = TryOnImagePrep.person(Uint8List.fromList(raw));
      _loadingPerson = false;
      _userImageError = null;
    });
  }

  Future<void> _loadPersonFromUrl(String url) async {
    setState(() => _loadingPerson = true);
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode >= 200 && res.statusCode < 300 && mounted) {
        _applyPersonBytes(res.bodyBytes);
      } else if (mounted) {
        setState(() {
          _loadingPerson = false;
          _userImageError = 'Could not load your captured photo.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPerson = false;
        _userImageError = 'Could not load photo: $e';
      });
    }
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: TryOnImagePrep.personMaxSide.toDouble(),
      imageQuality: TryOnImagePrep.jpegQuality,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    _applyPersonBytes(bytes);
    setState(() => _error = null);
  }

  Future<Uint8List> _loadGarmentBytes(String name) async {
    return TryOnGarmentService.loadGarmentBytes(name);
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    var p = 0.0;
    setState(() {
      _progress = 0;
      _progressLabel = _labelForProgress(0);
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final step = p < 30 ? 2.8 : p < 60 ? 1.4 : p < 85 ? 0.7 : 0.2;
      p = (p + step).clamp(0, 94);
      final rounded = p.round();
      if (mounted) {
        setState(() {
          _progress = rounded;
          _progressLabel = _labelForProgress(rounded);
        });
      }
    });
  }

  void _stopProgressTimer({int? finalValue}) {
    _progressTimer?.cancel();
    _progressTimer = null;
    if (finalValue != null && mounted) {
      setState(() {
        _progress = finalValue;
        _progressLabel = _labelForProgress(finalValue);
      });
    }
  }

  Future<void> _runTryOn() async {
    final garment = _selectedGarment;
    if (_personBytes == null || garment == null) {
      setState(() {
        _error =
            'Upload your photo (shalwar kameez / plain clothes, front view) and pick a kurta.';
      });
      return;
    }
    setState(() {
      _error = null;
      _resultImageError = null;
      _runningTryOn = true;
      _resultBytes = null;
    });
    _startProgressTimer();
    try {
      final garmBytes = await _loadGarmentBytes(garment);
      final result = await _api.runTryOn(
        humanJpeg: _personBytes!,
        garmentJpeg: garmBytes,
      );
      _stopProgressTimer(finalValue: 100);
      if (!mounted) return;
      if (result.bytes != null) {
        setState(() {
          _resultBytes = Uint8List.fromList(result.bytes!);
          _runningTryOn = false;
        });
      } else {
        setState(() {
          _runningTryOn = false;
          _resultImageError =
              'Try-on finished but result image could not be loaded.';
        });
      }
    } on TryOnApiException catch (e) {
      _stopProgressTimer();
      if (!mounted) return;
      setState(() {
        _runningTryOn = false;
        _error = e.message.contains('Failed to fetch') || e.message.contains('SocketException')
            ? 'Cannot reach try-on API. Start it with: npm run api (port 8765).'
            : e.message;
      });
    } catch (e) {
      _stopProgressTimer();
      if (!mounted) return;
      setState(() {
        _runningTryOn = false;
        _error = e.toString();
      });
    }
  }

  void _downloadResult() {
    if (_resultBytes == null) return;
    final base = (_selectedGarment ?? 'tryon')
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    downloadTryOnImage(_resultBytes!, 'kurta-tryon-$base.jpg');
  }

  /// Find tailor — available even before try-on completes.
  void _openFindTailor() {
    final g = _selectedGarment;
    if (g != null && g.isNotEmpty) {
      TryOnOrderSession.instance.applyGarment(g);
    }
    TryOnOrderSession.instance.tryOnResultBytes = _resultBytes;
    TryOnFindTailorScreen.open(context);
  }

  String? get _bannerError =>
      _error ?? _userImageError ?? _garmentPreviewError ?? _resultImageError;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      backgroundColor: TryOnTheme.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Material(
          color: TryOnTheme.white,
          elevation: 0,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TryOnTheme.gray)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (!widget.embeddedInNav)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: TryOnTheme.brown),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    if (!widget.embeddedInNav) const SizedBox(width: 4),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: TryOnTheme.cream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0x1F6B4F3F)),
                      ),
                      alignment: Alignment.center,
                      child: Text('S', style: TryOnTheme.heading(size: 18)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Smart Fiatio', style: TryOnTheme.heading(size: 18)),
                        Text(
                          'VIRTUAL FITTING',
                          style: TryOnTheme.body(
                            size: 10,
                            weight: FontWeight.w500,
                            color: TryOnTheme.brownMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _openFindTailor,
                      icon: const Icon(Icons.person_search, size: 18, color: Colors.white),
                      label: const Text(
                        'Find tailor',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (MediaQuery.sizeOf(context).width > 900)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TryOnTheme.cream,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Color(0x1A6B4F3F)),
                        ),
                        child: Text(
                          _apiModeLabel,
                          style: TryOnTheme.body(size: 11, weight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          widget.embeddedInNav ? 88 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                      TryOnFittingFlowHeader(
                        onFindTailor: _openFindTailor,
                        landmarkCount: widget.landmarkCount,
                      ),
                      const SizedBox(height: 16),
                      if (_bannerError != null) _ErrorBanner(message: _bannerError!),
                      if (wide)
                        _PipelineRow(
                          step1: _stepUpload(),
                          step2: _stepGarment(),
                          step3: _stepOutput(),
                        )
                      else
                        Column(
                          children: [
                            _stepUpload(),
                            _pipelineArrow(vertical: true),
                            _stepGarment(),
                            _pipelineArrow(vertical: true),
                            _stepOutput(),
                          ],
                        ),
                      const SizedBox(height: 20),
                      const Divider(color: TryOnTheme.gray),
                      const SizedBox(height: 16),
                      Text(
                        'Smart Fiatio · Virtual Shalwar Kameez Try-On',
                        textAlign: TextAlign.center,
                        style: TryOnTheme.body(size: 12, color: TryOnTheme.brownMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kurta images courtesy of Affordable.pk',
                        textAlign: TextAlign.center,
                        style: TryOnTheme.body(size: 12, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pipelineArrow({required bool vertical}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: vertical ? 8 : 0,
        horizontal: vertical ? 0 : 4,
      ),
      child: Icon(
        vertical ? Icons.arrow_downward : Icons.arrow_forward,
        color: const Color(0x596B4F3F),
        size: 24,
      ),
    );
  }

  Widget _stepUpload() {
    return _PipelineStep(
      stepNumber: 1,
      title: 'Upload your photo',
      note:
          'Image only · you in shalwar kameez or plain clothes · front view · standing',
      child: GestureDetector(
        onTap: _pickPhoto,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 220),
          decoration: BoxDecoration(
            color: _personBytes != null ? TryOnTheme.white : TryOnTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _personBytes != null
                  ? TryOnTheme.cream
                  : const Color(0x406B4F3F),
              width: 1.5,
            ),
          ),
          child: _loadingPerson
              ? const Center(child: CircularProgressIndicator(color: TryOnTheme.brown))
              : _userImageError != null
                  ? _CompactErr(_userImageError!)
                  : _personBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _personBytes!,
                            fit: BoxFit.contain,
                            height: 240,
                            width: double.infinity,
                          ),
                        )
                      : _DropPlaceholder(onTap: _pickPhoto),
        ),
      ),
    );
  }

  Widget _stepGarment() {
    return _PipelineStep(
      stepNumber: 2,
      title: 'Select kurta / kameez',
      badge: '${_garments.length}',
      note: 'Scroll to browse all kurtas',
      flex: 1.55,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GarmentHero(
            garmentName: _selectedGarment,
            error: _garmentPreviewError,
            onError: () {
              final n = _selectedGarment;
              if (n != null) {
                setState(() {
                  _brokenGarments.add(n);
                  _garmentPreviewError = 'This kurta image could not be displayed.';
                });
              }
            },
          ),
          const SizedBox(height: 6),
          Text(
            'ALL KURTAS ↓',
            textAlign: TextAlign.center,
            style: TryOnTheme.body(
              size: 11,
              weight: FontWeight.w600,
              color: TryOnTheme.brownMuted,
            ),
          ),
          const SizedBox(height: 6),
          if (_loadingGarments)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 220,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _garments.length,
                itemBuilder: (context, i) {
                  final name = _garments[i];
                  final selected = name == _selectedGarment;
                  final broken = _brokenGarments.contains(name);
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedGarment = name;
                      _garmentPreviewError = null;
                      _error = null;
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: TryOnTheme.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? TryOnTheme.brown
                              : broken
                                  ? TryOnTheme.errBorder
                                  : TryOnTheme.gray,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: TryOnTheme.brown.withValues(alpha: 0.15))]
                            : null,
                      ),
                      child: broken
                          ? Center(
                              child: Text(
                                '!',
                                style: TryOnTheme.body(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: TryOnTheme.errText,
                                ),
                              ),
                            )
                          : Image.asset(
                              TryOnGarmentService.assetImagePath(name),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() => _brokenGarments.add(name));
                                  }
                                });
                                return const Center(child: Text('!'));
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_runningTryOn ||
                      _personBytes == null ||
                      _selectedGarment == null ||
                      _userImageError != null ||
                      _garmentPreviewError != null)
                  ? null
                  : _runTryOn,
              style: ElevatedButton.styleFrom(
                backgroundColor: TryOnTheme.brown,
                foregroundColor: TryOnTheme.white,
                disabledBackgroundColor: TryOnTheme.brown.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _runningTryOn
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TryOnTheme.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Processing…',
                          style: TryOnTheme.body(
                            size: 14,
                            weight: FontWeight.w600,
                            color: TryOnTheme.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Run Try-On (HF ~30 sec)',
                      style: TryOnTheme.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: TryOnTheme.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepOutput() {
    final hasResult = _resultBytes != null && !_runningTryOn;
    return _PipelineStep(
      stepNumber: 3,
      title: 'Output',
      flex: 1.25,
      trailing: _runningTryOn
          ? _StatusChip('Running', loading: true)
          : hasResult
              ? const _StatusChip('Done', loading: false)
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_runningTryOn) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _progressLabel.isEmpty ? 'Starting…' : _progressLabel,
                    style: TryOnTheme.body(size: 13, weight: FontWeight.w500),
                  ),
                ),
                Text(
                  '$_progress%',
                  style: TryOnTheme.heading(size: 22),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 12,
                backgroundColor: TryOnTheme.gray,
                color: TryOnTheme.brown,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 380),
              decoration: BoxDecoration(
                color: TryOnTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TryOnTheme.gray),
              ),
              alignment: Alignment.center,
              child: _runningTryOn
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: TryOnTheme.brown,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'AI try-on in progress…',
                          style: TryOnTheme.body(size: 13, color: TryOnTheme.brownMuted),
                        ),
                      ],
                    )
                  : _resultImageError != null
                      ? _CompactErr(_resultImageError!)
                      : hasResult
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.memory(
                                _resultBytes!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Text(
                              'Your kurta try-on result will appear here',
                              textAlign: TextAlign.center,
                              style: TryOnTheme.body(size: 13, color: TryOnTheme.brownMuted),
                            ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openFindTailor,
              icon: const Icon(Icons.person_search, size: 20),
              label: const Text('Find tailor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                side: const BorderSide(color: Color(0xFF059669)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (hasResult && _resultImageError == null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _downloadResult,
              style: OutlinedButton.styleFrom(
                foregroundColor: TryOnTheme.brown,
                side: const BorderSide(color: TryOnTheme.brown),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Download picture',
                style: TryOnTheme.body(size: 13, weight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({
    required this.step1,
    required this.step2,
    required this.step3,
  });

  final Widget step1;
  final Widget step2;
  final Widget step3;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: step1),
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Icon(Icons.arrow_forward, color: Color(0x596B4F3F), size: 24),
          ),
          Expanded(flex: 155, child: step2),
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Icon(Icons.arrow_forward, color: Color(0x596B4F3F), size: 24),
          ),
          Expanded(flex: 125, child: step3),
        ],
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.stepNumber,
    required this.title,
    required this.child,
    this.note,
    this.badge,
    this.trailing,
    this.flex = 1,
    this.scrollable = false,
  });

  final int stepNumber;
  final String title;
  final String? note;
  final String? badge;
  final Widget child;
  final Widget? trailing;
  final double flex;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _StepBadge(stepNumber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TryOnTheme.body(size: 14, weight: FontWeight.w600),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TryOnTheme.gray,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge!, style: TryOnTheme.body(size: 11)),
              ),
            if (trailing != null) trailing!,
          ],
        ),
        const Divider(color: TryOnTheme.gray, height: 20),
        if (note != null) ...[
          Text(note!, style: TryOnTheme.body(size: 12, color: TryOnTheme.brownMuted)),
          const SizedBox(height: 10),
        ],
        Expanded(child: child),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TryOnTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TryOnTheme.gray),
        boxShadow: [
          BoxShadow(
            color: TryOnTheme.brown.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: scrollable
          ? SingleChildScrollView(child: SizedBox(height: 720, child: content))
          : SizedBox(height: 720, child: content),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: TryOnTheme.cream,
        shape: BoxShape.circle,
        border: Border.all(color: Color(0x1A6B4F3F)),
      ),
      alignment: Alignment.center,
      child: Text(
        '$n',
        style: TryOnTheme.body(size: 12, weight: FontWeight.w700),
      ),
    );
  }
}

class _GarmentHero extends StatelessWidget {
  const _GarmentHero({
    required this.garmentName,
    this.error,
    this.onError,
  });

  final String? garmentName;
  final String? error;
  final VoidCallback? onError;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: TryOnTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error != null ? TryOnTheme.errBorder : TryOnTheme.cream,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: TryOnTheme.brown.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: error != null
          ? _CompactErr(error!)
          : garmentName == null
              ? Center(
                  child: Text(
                    'Pick a kurta from the list below',
                    style: TryOnTheme.body(size: 13, color: TryOnTheme.brownMuted),
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        TryOnGarmentService.assetImagePath(garmentName!),
                        fit: BoxFit.contain,
                        height: 280,
                        errorBuilder: (_, __, ___) {
                          onError?.call();
                          return const _CompactErr('Image failed to load');
                        },
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: TryOnTheme.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: TryOnTheme.gray),
                        ),
                        child: Text(
                          TryOnGarmentService.displayName(garmentName!),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TryOnTheme.body(size: 11, weight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DropPlaceholder extends StatelessWidget {
  const _DropPlaceholder({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TryOnTheme.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload, color: TryOnTheme.brown, size: 22),
            ),
            const SizedBox(height: 12),
            Text('Upload your photo', style: TryOnTheme.body(size: 14, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Portrait · full or upper body · JPG / PNG',
              style: TryOnTheme.body(size: 12, color: TryOnTheme.brownMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TryOnTheme.errBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TryOnTheme.errBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TryOnTheme.body(size: 13, color: TryOnTheme.errText),
      ),
    );
  }
}

class _CompactErr extends StatelessWidget {
  const _CompactErr(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TryOnTheme.body(size: 12, color: TryOnTheme.errText),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, {required this.loading});
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: loading ? TryOnTheme.cream : Color(0x146B4F3F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TryOnTheme.body(size: 10, weight: FontWeight.w600),
      ),
    );
  }
}
