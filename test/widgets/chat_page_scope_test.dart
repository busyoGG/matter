import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/app.dart';
import 'package:matter/pages/chat/chat_page.dart';
import 'package:matter/pages/chat/search_bar.dart';
import 'package:matter/providers/chat_provider.dart';
import 'package:matter/widgets/frosted_header_background.dart';
import 'package:matter/widgets/home_background.dart';
import 'package:matter/widgets/soft_superellipse_border.dart';
import 'package:matter/src/rust/api/matrix.dart';

void _expectNoRegionRepaintBoundary() {
  expect(
    find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == 'RegionRepaintBoundary',
    ),
    findsNothing,
  );
}

void _expectHeaderVisualPath({int componentCount = 1}) {
  final header = find.byType(GradientFrostedHeaderBackground);
  final headerBlur = find.descendant(
    of: header,
    matching: find.byType(GradientBackdropBlur),
  );
  expect(
    find.ancestor(of: headerBlur, matching: find.byType(StretchEffect)),
    findsNothing,
  );
  expect(find.byType(ShaderMask), findsNothing);
  final expectedFilterCount = ui.ImageFilter.isShaderFilterSupported
      ? componentCount * 5
      : componentCount;
  expect(
    find.descendant(of: headerBlur, matching: find.byType(BackdropFilter)),
    findsNWidgets(expectedFilterCount),
  );
  _expectNoRegionRepaintBoundary();
}

void main() {
  ChatRoom room({
    required String id,
    required String name,
    required String roomType,
  }) => ChatRoom(
    id: id,
    name: name,
    lastMessage: '',
    lastMessageTime: '0',
    lastEventId: '',
    unreadCount: 0,
    isMarkedUnread: false,
    roomType: roomType,
    isEncrypted: false,
    isMuted: false,
    roomState: 'joined',
  );

  testWidgets('direct message scope excludes group rooms', (tester) async {
    final directMessage = room(
      id: '!dm:example.org',
      name: 'Alice',
      roomType: 'dm',
    );
    final groupRoom = room(
      id: '!group:example.org',
      name: 'General',
      roomType: 'group',
    );
    final container = ProviderContainer(
      overrides: [
        chatRoomsProvider.overrideWith(
          (ref) async => [directMessage, groupRoom],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 600,
              child: ChatPage(
                embedded: true,
                title: '私聊',
                directMessagesOnly: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('General'), findsNothing);
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    final shape = fab.shape! as SoftSuperellipseBorder;
    expect(shape.borderRadius, BorderRadius.circular(18));
  });

  testWidgets('space scope shows only the selected space rooms', (
    tester,
  ) async {
    const spaceId = '!space:example.org';
    final spaceRoom = room(
      id: '!room:example.org',
      name: 'Announcements',
      roomType: 'group',
    );
    final container = ProviderContainer(
      overrides: [
        spaceChildrenProvider(spaceId).overrideWith((ref) async => [spaceRoom]),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 600,
              child: ChatPage(
                embedded: true,
                title: 'Workspace',
                spaceId: spaceId,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Announcements'), findsOneWidget);
  });

  testWidgets(
    'home search stays inside CustomScrollView with realtime Kawase paths',
    (tester) async {
      final container = ProviderContainer(
        overrides: [chatRoomsProvider.overrideWith((ref) async => const [])],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(viewPadding: EdgeInsets.only(top: 24)),
              child: ChatPage(title: '首页'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final header = find.byType(GradientFrostedHeaderBackground);
      final searchBar = find.byType(ChatSearchBar);
      expect(
        find.descendant(of: find.byType(CustomScrollView), matching: searchBar),
        findsOneWidget,
      );
      expect(header, findsOneWidget);
      expect(
        find.descendant(of: header, matching: find.byType(CustomScrollView)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.byType(StretchEffect)),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('header-status-bar-surface-guard')),
        findsNothing,
      );

      final titleRect = tester.getRect(find.text('首页'));
      expect(titleRect.top, greaterThanOrEqualTo(24));
      expect(titleRect.bottom, lessThanOrEqualTo(80));
      final searchRect = tester.getRect(searchBar);
      expect(searchRect.top, closeTo(80, 0.001));
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.shape, isA<SoftSuperellipseBorder>());
      final shape = fab.shape! as SoftSuperellipseBorder;
      expect(shape.borderRadius, BorderRadius.circular(24));
      _expectHeaderVisualPath();
    },
  );

  testWidgets('mobile navigation bar hides and reappears with list direction', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final rooms = [
      for (var index = 0; index < 24; index++)
        room(
          id: '!room-$index:example.org',
          name: 'Room $index',
          roomType: 'group',
        ),
    ];
    final container = ProviderContainer(
      overrides: [chatRoomsProvider.overrideWith((ref) async => rooms)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MatterApp()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final homeBackground = find.byType(HomeBackgroundPage);
    expect(homeBackground, findsOneWidget);
    expect(
      find.descendant(of: homeBackground, matching: find.byType(PageView)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: homeBackground, matching: find.byType(BackdropGroup)),
      findsOneWidget,
    );
    final scrollView = find.byType(CustomScrollView);
    final navigationSlide = find.byKey(
      const ValueKey('navigation-visibility-slide'),
    );
    expect(scrollView, findsOneWidget);
    expect(navigationSlide, findsOneWidget);
    expect(tester.widget<AnimatedSlide>(navigationSlide).offset, Offset.zero);

    await tester.drag(scrollView, const Offset(0, -240));
    await tester.pump();
    expect(
      tester.widget<AnimatedSlide>(navigationSlide).offset,
      const Offset(0, 1.2),
    );
    final hiddenFrameSize = tester.getSize(
      find.byKey(const ValueKey('navigation-frame')),
    );

    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedSlide>(navigationSlide).offset,
      const Offset(0, 1.2),
    );

    await tester.drag(scrollView, const Offset(0, 240));
    await tester.pump();
    expect(tester.widget<AnimatedSlide>(navigationSlide).offset, Offset.zero);
    expect(
      tester.getSize(find.byKey(const ValueKey('navigation-frame'))),
      hiddenFrameSize,
    );
  });
}
