import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kzdownloader/l10n/arb/app_localizations.dart';
import 'package:kzdownloader/core/download/providers/prefetched_metadata.dart';
import 'package:kzdownloader/views/chat/widgets/input/chat_input_area.dart';
import 'package:kzdownloader/views/chat/widgets/window_button.dart';
import 'package:ultimate_flutter_icons/ficon.dart';
import 'package:ultimate_flutter_icons/icons/rx.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;

class HomeScreen extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String selectedProvider;
  final bool showVideoOptions;
  final bool isAudio;
  final bool isSummaryMode;
  final bool isPrefetchingMetadata;
  final bool metadataFetchCompleted;
  final bool showInitialAnimation;
  final VoidCallback onSubmit;
  final Function(String) onProviderChanged;
  final String selectedQuality;
  final Function(String) onQualityChanged;
  final Function(bool) onIsAudioChanged;
  final Function(bool) onSummarizeOnlyChanged;
  final Function(bool) onPrefetchStateChanged;
  final VoidCallback onMetadataFetched;
  final String expectedChecksum;
  final String checksumAlgorithm;
  final Function(String)? onChecksumChanged;
  final Function(String)? onAlgorithmChanged;
  final Function(int)? onM3U8VariantIndexChanged;
  final Function(int)? onParallelDownloadsChanged;
  final Function(Set<int>)? onSelectedVideoIndicesChanged;
  final ValueChanged<String?>? onAdvancedDownloadPathChanged;
  final ValueChanged<int?>? onAdvancedSpeedLimitKbpsChanged;

  const HomeScreen({
    super.key,
    required this.controller,
    this.focusNode,
    required this.selectedProvider,
    required this.showVideoOptions,
    required this.isAudio,
    required this.isSummaryMode,
    required this.isPrefetchingMetadata,
    required this.metadataFetchCompleted,
    required this.showInitialAnimation,
    required this.onSubmit,
    required this.onProviderChanged,
    required this.selectedQuality,
    required this.onQualityChanged,
    required this.onIsAudioChanged,
    required this.onSummarizeOnlyChanged,
    required this.onPrefetchStateChanged,
    required this.onMetadataFetched,
    this.expectedChecksum = '',
    this.checksumAlgorithm = 'MD5',
    this.onChecksumChanged,
    this.onAlgorithmChanged,
    this.onM3U8VariantIndexChanged,
    this.onParallelDownloadsChanged,
    this.onSelectedVideoIndicesChanged,
    this.onAdvancedDownloadPathChanged,
    this.onAdvancedSpeedLimitKbpsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    // Track whether a thumbnail preview is visible to enable scrolling + shift content up
    final prefetchStatus = ref.watch(prefetchStatusProvider);
    final prefetchedMap = ref.watch(prefetchedMetadataProvider);
    final currentUrl = controller.text;
    final hasThumbnail = prefetchStatus == PrefetchStatus.ready &&
        prefetchedMap[currentUrl]?.thumbnail != null &&
        prefetchedMap[currentUrl]!.thumbnail!.isNotEmpty;

    return MouseRegion(
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: _GeometricFallingStars(isLightTheme: isLightTheme),
            ),
          ),
          Positioned.fill(
            child: _AnimatedScrollContent(
              hasThumbnail: hasThumbnail,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.32),
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 10),
                          child: child,
                        ),
                      ),
                      child: _buildBrandLogo(isLightTheme, colorScheme),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          (!showVideoOptions ? 0.075 : 0.05)),
                  Center(
                    child: SizedBox(
                      width: 620,
                      child: ChatInputArea(
                        controller: controller,
                        focusNode: focusNode,
                        selectedProvider: selectedProvider,
                        showVideoOptions: showVideoOptions,
                        selectedQuality: selectedQuality,
                        isAudio: isAudio,
                        summarizeOnly: isSummaryMode,
                        isCentered: true,
                        onSubmit: onSubmit,
                        onProviderChanged: onProviderChanged,
                        onQualityChanged: onQualityChanged,
                        onIsAudioChanged: onIsAudioChanged,
                        onSummarizeOnlyChanged: onSummarizeOnlyChanged,
                        onPrefetchStateChanged: onPrefetchStateChanged,
                        onMetadataFetched: onMetadataFetched,
                        expectedChecksum: expectedChecksum,
                        checksumAlgorithm: checksumAlgorithm,
                        onChecksumChanged: onChecksumChanged != null
                            ? (val) => onChecksumChanged!(val)
                            : null,
                        onAlgorithmChanged: onAlgorithmChanged != null
                            ? (val) => onAlgorithmChanged!(val)
                            : null,
                        onM3U8VariantIndexChanged:
                            onM3U8VariantIndexChanged != null
                                ? (idx) => onM3U8VariantIndexChanged!(idx)
                                : null,
                        onParallelDownloadsChanged:
                            onParallelDownloadsChanged != null
                                ? (val) => onParallelDownloadsChanged!(val)
                                : null,
                        onSelectedVideoIndicesChanged:
                            onSelectedVideoIndicesChanged != null
                                ? (indices) =>
                                    onSelectedVideoIndicesChanged!(indices)
                                : null,
                        onAdvancedDownloadPathChanged:
                            onAdvancedDownloadPathChanged,
                        onAdvancedSpeedLimitKbpsChanged:
                            onAdvancedSpeedLimitKbpsChanged,
                      ),
                    ),
                  ),
                  if (!(isPrefetchingMetadata && controller.text.isNotEmpty))
                    Center(
                      child: _buildStatusIndicator(
                        context,
                        colorScheme,
                        showInitialAnimation,
                        isPrefetchingMetadata,
                        metadataFetchCompleted,
                        controller.text,
                        showVideoOptions,
                      ),
                    ),
                ],
              ), // Column
            ),
          ),
          // Transparent drag area to move the window (on top of content)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 48,
            child: DragToMoveArea(
              child: SizedBox.expand(),
            ),
          ),
          // Window Control Buttons (Windows & Linux only)
          if (!Platform.isMacOS) ...[
            Positioned(
              top: 20,
              right: 16,
              child: Row(
                children: [
                  WindowButton(
                    icon: Icons.remove,
                    onPressed: () => windowManager.minimize(),
                  ),
                  const SizedBox(width: 2),
                  WindowButton(
                    icon: Icons.crop_square,
                    onPressed: () async {
                      if (await windowManager.isMaximized()) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                  ),
                  const SizedBox(width: 2),
                  WindowButton(
                    icon: Icons.close,
                    isClose: true,
                    onPressed: () => windowManager.close(),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildBrandLogo(bool isLightTheme, ColorScheme colorScheme) {
    if (isLightTheme) {
      return Container(
        padding: const EdgeInsets.only(
          top: 18,
          bottom: 18,
          right: 24,
          left: 20,
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.125),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 2),
              )
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/kz_white.png', height: 40),
            const SizedBox(width: 12),
            Text(
              'Downloader',
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.only(
          top: 18,
          bottom: 18,
          right: 24,
          left: 20,
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: colorScheme.tertiary,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 2),
              )
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/kz_tr.png', height: 40),
            const SizedBox(width: 12),
            Text(
              'Downloader',
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    ColorScheme colorScheme,
    bool showInitialAnimation,
    bool isPrefetchingMetadata,
    bool metadataFetchCompleted,
    String controllerText,
    bool showVideoOptions,
  ) {
    final l10n = AppLocalizations.of(context)!;
    dynamic icon;
    String text;

    if (showInitialAnimation) {
      icon = Icons.hourglass_empty;
      text = l10n.almostReady;
    } else if (isPrefetchingMetadata && controllerText.isNotEmpty) {
      icon = Icons.downloading;
      text = l10n.downloadingMetadata;
    } else if (metadataFetchCompleted && controllerText.isNotEmpty) {
      icon = Icons.check_circle_outline;
      text = l10n.metadataReady;
    } else {
      icon = RX.RxRocket;
      text = l10n.readyToDownload;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: Stack(
        key: ValueKey<String>('${icon.toString()}-$text'),
        children: [
          Container(
            decoration: BoxDecoration(
                color: colorScheme.tertiary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                    left: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.15)),
                    right: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.15)),
                    bottom: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.15))),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 2),
                  )
                ]),
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon is FIconObject
                    ? FIcon(
                        icon,
                        color: colorScheme.primary,
                        size: 20,
                      )
                    : Icon(
                        icon,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                const SizedBox(width: 8),
                Text(text),
              ],
            ),
          ),
          if (showVideoOptions)
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                        Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.0),
                        Theme.of(context).scaffoldBackgroundColor
                      ],
                          begin: Alignment.bottomCenter,
                          end: AlignmentGeometry.topCenter)),
                ))
        ],
      ),
    );
  }
}

// ── Animated scrollable content wrapper ───────────────────────────────────────
// Combines Transform.translate for smooth visual shift with SingleChildScrollView
// so content is never cut off when a thumbnail preview appears.
class _AnimatedScrollContent extends StatefulWidget {
  final bool hasThumbnail;
  final Widget child;

  const _AnimatedScrollContent({
    required this.hasThumbnail,
    required this.child,
  });

  @override
  State<_AnimatedScrollContent> createState() => _AnimatedScrollContentState();
}

class _AnimatedScrollContentState extends State<_AnimatedScrollContent>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _animationController;
  late final Animation<double> _curveAnimation;

  static const double shiftAmount = 180.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _curveAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    if (widget.hasThumbnail) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedScrollContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasThumbnail && !oldWidget.hasThumbnail) {
      _animationController.forward();
    } else if (!widget.hasThumbnail && oldWidget.hasThumbnail) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      child: AnimatedBuilder(
        animation: _curveAnimation,
        builder: (context, child) {
          final offset = _curveAnimation.value * shiftAmount;
          return Transform.translate(
            offset: Offset(0, -offset),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ── Geometric Falling Stars ─────────────────────────────────────────────────

/// Data model for a single falling geometric meteor.
class _FallingStar {
  double x; // normalised 0..1
  double y; // normalised 0..1
  double speed; // normalised units per second
  double angle; // fall direction in radians
  double size; // pixel radius
  double rotation; // current rotation angle
  double rotationSpeed; // radians per second
  double opacity;
  double tailLength; // px, length of the tapered tail
  double tailWidthFactor; // relative to size, width of tail base
  List<Offset> vertices; // polygon shape (relative to centre)
  List<_DebrisParticle> debris;

  _FallingStar({
    required this.x,
    required this.y,
    required this.speed,
    required this.angle,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
    required this.tailLength,
    required this.tailWidthFactor,
    required this.vertices,
    required this.debris,
  });
}

/// A small geometric debris fragment trailing behind a meteor.
class _DebrisParticle {
  double offsetX; // offset from parent star (px)
  double offsetY;
  double size;
  double opacity;
  double driftX; // per-second drift
  double driftY;
  List<Offset> shape; // tiny polygon

  _DebrisParticle({
    required this.offsetX,
    required this.offsetY,
    required this.size,
    required this.opacity,
    required this.driftX,
    required this.driftY,
    required this.shape,
  });
}

class _GeometricFallingStars extends StatefulWidget {
  final bool isLightTheme;

  const _GeometricFallingStars({required this.isLightTheme});

  @override
  State<_GeometricFallingStars> createState() => _GeometricFallingStarsState();
}

class _GeometricFallingStarsState extends State<_GeometricFallingStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_FallingStar> _stars = [];

  // --- Config ---
  // Reduced from 7 -> 5: the home screen already has a lot of UI, so a
  // slightly sparser field reads as "comet fragments" instead of "meteor
  // shower" and keeps focus on the search bar / logo.
  static const int _maxStars = 5;
  static const double _spawnInterval = 1.8; // seconds between spawns
  double _spawnTimer = 0;

  // Seeded pseudo-random for deterministic-ish look
  final _rng = _SimpleRng(42);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ctrl.addListener(_tick);
  }

  void _tick() {
    const dt = 1.0 / 60.0; // ~60fps
    _spawnTimer += dt;

    // Spawn new stars periodically
    if (_spawnTimer >= _spawnInterval && _stars.length < _maxStars) {
      _spawnTimer = 0;
      _stars.add(_createStar());
    }

    // Update stars
    for (final star in _stars) {
      star.x += math.cos(star.angle) * star.speed * dt;
      star.y += math.sin(star.angle) * star.speed * dt;
      star.rotation += star.rotationSpeed * dt;

      // Update debris
      for (final d in star.debris) {
        d.offsetX += d.driftX * dt;
        d.offsetY += d.driftY * dt;
        d.opacity = (d.opacity - 0.3 * dt).clamp(0.0, 1.0);
      }
      // Remove faded debris
      star.debris.removeWhere((d) => d.opacity <= 0);

      // Spawn new debris trail
      if (_rng.nextDouble() < 0.4) {
        star.debris.add(_createDebris(star));
      }
    }

    // Remove off-screen stars
    _stars.removeWhere((s) => s.y > 1.3 || s.x < -0.3 || s.x > 1.3);

    setState(() {});
  }

  _FallingStar _createStar() {
    final side = _rng.nextDouble(); // which edge to spawn from
    double startX, startY;

    if (side < 0.7) {
      // Top edge
      startX = _rng.nextDouble();
      startY = -0.05;
    } else {
      // Right edge
      startX = 1.05;
      startY = _rng.nextDouble() * 0.4;
    }

    final vertexCount = 4 + _rng.nextInt(4); // 4–7 vertices
    final starSize = 8.0 + _rng.nextDouble() * 24.0;

    return _FallingStar(
      x: startX,
      y: startY,
      speed: 0.06 + _rng.nextDouble() * 0.12,
      angle: math.pi *
          (0.62 + _rng.nextDouble() * 0.09), // ~112°–128° (uniform down-left)
      size: starSize,
      rotation: _rng.nextDouble() * math.pi * 2,
      rotationSpeed: (_rng.nextDouble() - 0.5) * 3.0,
      opacity: 0.5 + _rng.nextDouble() * 0.5,
      // Tail scales with the meteor's own size so bigger fragments get a
      // proportionally longer, more visible tail — like the logo's comet.
      tailLength: starSize * (4.0 + _rng.nextDouble() * 3.0),
      tailWidthFactor: 0.5 + _rng.nextDouble() * 0.35,
      vertices: _generatePolygon(vertexCount, starSize),
      debris: [],
    );
  }

  List<Offset> _generatePolygon(int sides, double radius) {
    final verts = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi / sides) * i;
      // Vary radius for jagged crystalline look
      final r = radius * (0.5 + _rng.nextDouble() * 0.5);
      verts.add(Offset(math.cos(angle) * r, math.sin(angle) * r));
    }
    return verts;
  }

  _DebrisParticle _createDebris(_FallingStar parent) {
    final debrisSize = 1.5 + _rng.nextDouble() * 4.0;
    final sides = 3 + _rng.nextInt(3);
    return _DebrisParticle(
      offsetX: 0,
      offsetY: 0,
      size: debrisSize,
      opacity: 0.6 + _rng.nextDouble() * 0.4,
      // Drift opposite to travel direction (trail behind)
      driftX: -math.cos(parent.angle) * (30 + _rng.nextDouble() * 60) +
          (_rng.nextDouble() - 0.5) * 40,
      driftY: -math.sin(parent.angle) * (30 + _rng.nextDouble() * 60) +
          (_rng.nextDouble() - 0.5) * 40,
      shape: _generatePolygon(sides, debrisSize),
    );
  }

  @override
  void dispose() {
    _ctrl.removeListener(_tick);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FallingStarsPainter(
        stars: _stars,
        isLightTheme: widget.isLightTheme,
      ),
      size: Size.infinite,
    );
  }
}

class _FallingStarsPainter extends CustomPainter {
  final List<_FallingStar> stars;
  final bool isLightTheme;

  _FallingStarsPainter({required this.stars, required this.isLightTheme});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final cx = star.x * size.width;
      final cy = star.y * size.height;

      // --- Draw the tapered comet tail first (furthest back layer) ---
      _drawTail(canvas, star, cx, cy);

      // --- Draw debris next (in front of the tail, behind the meteor) ---
      for (final d in star.debris) {
        final dx = cx + d.offsetX;
        final dy = cy + d.offsetY;
        final alpha = d.opacity * star.opacity;
        if (alpha <= 0) continue;

        final paint = Paint()
          ..color = isLightTheme
              ? Color.fromRGBO(30, 30, 30, alpha * 0.6)
              : Color.fromRGBO(200, 210, 220, alpha * 0.5)
          ..style = PaintingStyle.fill;

        final path = Path();
        if (d.shape.isNotEmpty) {
          path.moveTo(dx + d.shape[0].dx, dy + d.shape[0].dy);
          for (int i = 1; i < d.shape.length; i++) {
            path.lineTo(dx + d.shape[i].dx, dy + d.shape[i].dy);
          }
          path.close();
        }
        canvas.drawPath(path, paint);
      }

      // --- Draw main meteor polygon (on top) ---
      final meteorAlpha = star.opacity;
      if (meteorAlpha <= 0) continue;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(star.rotation);

      // Wireframe edges (geometric look)
      final edgePaint = Paint()
        ..color = isLightTheme
            ? Color.fromRGBO(20, 20, 20, meteorAlpha * 0.85)
            : Color.fromRGBO(220, 225, 230, meteorAlpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.miter;

      // Semi-transparent fill
      final fillPaint = Paint()
        ..color = isLightTheme
            ? Color.fromRGBO(40, 40, 40, meteorAlpha * 0.12)
            : Color.fromRGBO(200, 210, 220, meteorAlpha * 0.08)
        ..style = PaintingStyle.fill;

      final path = Path();
      if (star.vertices.isNotEmpty) {
        path.moveTo(star.vertices[0].dx, star.vertices[0].dy);
        for (int i = 1; i < star.vertices.length; i++) {
          path.lineTo(star.vertices[i].dx, star.vertices[i].dy);
        }
        path.close();
      }

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, edgePaint);

      // Internal structure lines (crystalline facets)
      if (star.vertices.length >= 4) {
        final innerPaint = Paint()
          ..color = isLightTheme
              ? Color.fromRGBO(30, 30, 30, meteorAlpha * 0.35)
              : Color.fromRGBO(200, 210, 220, meteorAlpha * 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7;

        // Draw lines from centre to alternating vertices
        for (int i = 0; i < star.vertices.length; i += 2) {
          canvas.drawLine(Offset.zero, star.vertices[i], innerPaint);
        }
      }

      canvas.restore();
    }
  }

  /// Draws a tapered, wireframe comet tail pointing opposite the direction
  /// of travel, fading out toward the tip — this is the element the pure
  /// meteor-shower version was missing versus the logo's comet mark.
  void _drawTail(Canvas canvas, _FallingStar star, double cx, double cy) {
    final alpha = star.opacity;
    if (alpha <= 0 || star.tailLength <= 0) return;

    // Direction the star travels; tail points the opposite way.
    final dirX = math.cos(star.angle);
    final dirY = math.sin(star.angle);
    final backX = -dirX;
    final backY = -dirY;
    // Perpendicular vector, used for the tail's base width.
    final perpX = -dirY;
    final perpY = dirX;

    final baseWidth = star.size * star.tailWidthFactor;
    final tipX = cx + backX * star.tailLength;
    final tipY = cy + backY * star.tailLength;

    // Base corners sit just at the edge of the meteor body, not its centre,
    // so the tail visually emerges from the crystal rather than overlapping it.
    final baseOffset = star.size * 0.35;
    final baseCx = cx + backX * baseOffset;
    final baseCy = cy + backY * baseOffset;
    final baseLeftX = baseCx + perpX * baseWidth * 0.5;
    final baseLeftY = baseCy + perpY * baseWidth * 0.5;
    final baseRightX = baseCx - perpX * baseWidth * 0.5;
    final baseRightY = baseCy - perpY * baseWidth * 0.5;

    final tailPath = Path()
      ..moveTo(baseLeftX, baseLeftY)
      ..lineTo(tipX, tipY)
      ..lineTo(baseRightX, baseRightY)
      ..close();

    // Gradient shader fades the tail from the meteor's colour down to fully
    // transparent at the tip, matching the logo's "dissolving" comet trail.
    final baseColor = isLightTheme
        ? Color.fromRGBO(20, 20, 20, alpha * 0.55)
        : Color.fromRGBO(220, 225, 230, alpha * 0.5);

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(baseCx, baseCy),
        Offset(tipX, tipY),
        [baseColor, baseColor.withOpacity(0.0)],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(tailPath, fillPaint);

    // A thin centre spine strengthens the "streak" read at small sizes.
    final spinePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(baseCx, baseCy),
        Offset(tipX, tipY),
        [baseColor, baseColor.withOpacity(0.0)],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(baseCx, baseCy), Offset(tipX, tipY), spinePaint);
  }

  @override
  bool shouldRepaint(covariant _FallingStarsPainter oldDelegate) => true;
}

/// Minimal pseudo-random number generator for deterministic aesthetics.
class _SimpleRng {
  int _state;
  _SimpleRng(this._state);

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }

  double nextDouble() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return (_state & 0xffffff) / 0xffffff;
  }
}
