import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/features/paint_editor/controllers/paint_controller.dart';
import 'package:pro_image_editor/features/paint_editor/widgets/paint_canvas.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

void main() {
  for (final mode in [PaintMode.rect, PaintMode.circle]) {
    testWidgets('$mode shows a preview while dragging', (tester) async {
      final canvasKey = GlobalKey<PaintCanvasState>();
      final controller = PaintController(
        color: Colors.red,
        mode: mode,
        fill: false,
        strokeWidth: 4,
        strokeMultiplier: 1,
        opacity: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaintCanvas(
              key: canvasKey,
              layers: const [],
              drawAreaSize: const Size(300, 300),
              editorBodySize: const Size(300, 300),
              layerStackScaleFactor: 1,
              paintCtrl: controller,
              eraserMode: EraserMode.partial,
              eraserRadius: 8,
              paintEditorConfigs: const PaintEditorConfigs(),
              onRefresh: () {},
              onCreated: (_) {},
              onRemoveLayer: (_) {},
              onRemovePartialStart: () {},
              onRemovePartialEnd: (_) {},
              onTap: (_) {},
            ),
          ),
        ),
      );

      final canvas = find.byKey(canvasKey);
      final start = tester.getTopLeft(canvas) + const Offset(40, 40);
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(start + const Offset(120, 80));
      await tester.pump();

      expect(controller.busy, isTrue);
      final preview = find.descendant(
        of: canvas,
        matching: find.byType(CustomPaint),
      );
      expect(preview, findsOneWidget);
      final painter = tester.widget<CustomPaint>(preview).painter;
      expect(painter, isA<DrawPaintItem>());
      expect((painter! as DrawPaintItem).item.offsets, hasLength(2));
      final firstEnd = controller.end;

      await gesture.moveTo(start + const Offset(180, 120));
      await tester.pump();

      expect(controller.end, isNot(firstEnd));
      expect(
        (tester.widget<CustomPaint>(preview).painter! as DrawPaintItem)
            .item
            .offsets
            .last,
        controller.end,
      );

      await gesture.up();
      controller.dispose();
    });
  }
}
