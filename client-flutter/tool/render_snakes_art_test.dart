// Run with flutter test tool/render_snakes_art_test.dart.
// Set SNAKES_BOARD_FONT to the path of Roboto-Regular.ttf pulled from Android.
// Encode build/snakes-art/*.png as lossless WebP in assets/images/snakes_boards/.
// Add a 384-pixel-wide lossless WebP for each design with a _thumb suffix.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/widgets/snakes_ladders_board.dart';

void main() {
  testWidgets('export the original Snakes board artwork', (tester) async {
    final fontPath = Platform.environment['SNAKES_BOARD_FONT'];
    if (fontPath == null) {
      fail('Set SNAKES_BOARD_FONT to an Android Roboto-Regular.ttf file.');
    }

    final output = Directory('build/snakes-art');
    await tester.runAsync(() async {
      await output.create(recursive: true);
      final font = await File(fontPath).readAsBytes();
      await (FontLoader(
        'sans-serif',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
    });

    final key = GlobalKey();
    final sourceAssets = _SourceArtworkBundle();
    for (final theme in const [
      'carnival',
      'royal',
      'neon',
      'classic',
      'jungle',
      'ocean',
      'astral',
      'volcano',
    ]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DefaultAssetBundle(
              bundle: sourceAssets,
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 400,
                  height: 430,
                  child: SnakesLaddersBoard(
                    key: ValueKey(theme),
                    snapshot: null,
                    mySeat: null,
                    boardTheme: theme,
                    showTitle: false,
                    showPieces: false,
                    animate: false,
                    onPieceTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 450)),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final board =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await board.toImage(pixelRatio: 3);
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${output.path}/$theme.png').writeAsBytes(
            bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        } finally {
          image.dispose();
        }
      });
    }
  });
}

// Render with the original painter even if baked assets are already installed.
class _SourceArtworkBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/images/snakes_boards/')) {
      throw FlutterError('Render Snakes source artwork');
    }
    return rootBundle.load(key);
  }
}
