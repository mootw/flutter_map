import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_example/misc/tile_providers.dart';
import 'package:flutter_map_example/widgets/drawer/menu_drawer.dart';
import 'package:flutter_map_example/widgets/show_no_web_perf_overlay_snackbar.dart';
import 'package:flutter_map_example/widgets/simplification_tolerance_slider.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart' as vec;

class PolygonPerfStressAltPage extends StatefulWidget {
  static const String route = '/polygon_perf_stress_alt';

  const PolygonPerfStressAltPage({super.key});

  @override
  State<PolygonPerfStressAltPage> createState() =>
      _PolygonPerfStressAltPageState();
}

class _PolygonPerfStressAltPageState extends State<PolygonPerfStressAltPage> {
  double simplificationTolerance = 0.33;
  bool useAltRendering = false;
  double borderThickness = 1;

  @override
  void initState() {
    super.initState();
    showNoWebPerfOverlaySnackbar(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polygon Stress Test 2')),
      drawer: const MenuDrawer(PolygonPerfStressAltPage.route),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds(
                  const LatLng(47, -120),
                  const LatLng(25, -90),
                ),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 145,
                  bottom: 175,
                ),
              ),
            ),
            children: [
              openStreetMapTileLayer,
              PolygonsLayer(
                  simplificationTolerance: simplificationTolerance,
                  useAltRendering: useAltRendering),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: RepaintBoundary(
              child: Column(
                children: [
                  SimplificationToleranceSlider(
                    tolerance: simplificationTolerance,
                    onChanged: (v) =>
                        setState(() => simplificationTolerance = v),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      UnconstrainedBox(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              const Tooltip(
                                message: 'Use Alternative Rendering Pathway',
                                child: Icon(Icons.speed_rounded),
                              ),
                              const SizedBox(width: 8),
                              Switch.adaptive(
                                value: useAltRendering,
                                onChanged: (v) =>
                                    setState(() => useAltRendering = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Not ideal that we have to re-parse the GeoJson every
                      // time this is changed, but the library gives no easy
                      // way to change it after
                      UnconstrainedBox(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              const Tooltip(
                                message: 'Border Thickness',
                                child: Icon(Icons.line_weight_rounded),
                              ),
                              if (MediaQuery.devicePixelRatioOf(context) > 1 &&
                                  borderThickness == 1)
                                const Tooltip(
                                  message: 'Screen has a high DPR: 1lp > 1dp',
                                  child: Icon(
                                    Icons.warning,
                                    color: Colors.amber,
                                  ),
                                ),
                              const SizedBox.shrink(),
                              ...List.generate(
                                4,
                                (i) {
                                  final thickness = i * i;
                                  return ChoiceChip(
                                    label: Text(
                                      thickness == 0
                                          ? 'None'
                                          : '${thickness}px',
                                    ),
                                    selected: borderThickness == thickness,
                                    shape: const StadiumBorder(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!kIsWeb)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: PerformanceOverlay.allEnabled(),
            ),
        ],
      ),
    );
  }
}

class PolygonsLayer extends StatelessWidget {
  final bool useAltRendering;
  final double simplificationTolerance;

  const PolygonsLayer(
      {super.key,
      required this.useAltRendering,
      required this.simplificationTolerance});

  @override
  Widget build(BuildContext context) {
    MapCamera mapCamera = MapCamera.maybeOf(context)!;
    final polygons = [
      for (int y = 0; y < 70; y++)
        for (int x = 0; x < 30; x++)
          Polygon(
              // Color per row (so 30 different colors)
              borderColor: Color.fromARGB(255, 255, 0 + (x * 5), 0 + (x * 5)),
              color: Color.fromRGBO(255, 0 + (x * 5), 0 + (x * 5), 0.075),
              borderStrokeWidth: mapCamera.zoom * 0.15,
              points: [
                // 31 segments per polygon
                for (double rot = 0; rot < 360; rot += 360 / 31)
                  LatLng(
                      47 +
                          (-x * 0.5) +
                          (math.sin(rot * vec.degrees2Radians) * 0.25),
                      -122 +
                          (y * 0.5) +
                          (math.cos(rot * vec.degrees2Radians) * 0.25)),
              ])
    ];

    final polygonsOutline = [
      for (final poly in polygons)
        Polygon(
            points: poly.points,
            borderColor: Colors.black,
            borderStrokeWidth: mapCamera.zoom * 0.30),
    ];

    return Stack(
      children: [
        PolygonLayer(
          polygonCulling: true,
          polygons: polygonsOutline,
          useAltRendering: useAltRendering,
          simplificationTolerance: simplificationTolerance,
        ),
        PolygonLayer(
          polygonCulling: true,
          polygons: polygons,
          useAltRendering: useAltRendering,
          simplificationTolerance: simplificationTolerance,
        ),
      ],
    );
  }
}
