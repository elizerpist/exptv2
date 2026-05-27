import 'package:flutter/material.dart';

import '../state/event_store.dart';
import '../widgets/event_bubble.dart';
import '../widgets/filter_bar.dart';
import '../widgets/permission_setup_card.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.store});

  final EventStore store;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    widget.store.start();
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.store.events;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PushParserV2'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(store: widget.store),
                ),
              );
              await widget.store.refreshStatus();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          PermissionSetupCard(
            status: widget.store.status,
            onOpenNotificationAccess: widget.store.openNotificationAccessSettings,
            onOpenAccessibility: widget.store.openAccessibilitySettings,
          ),
          Expanded(
            child: widget.store.loading
                ? const Center(child: CircularProgressIndicator())
                : events.isEmpty
                    ? const Center(child: Text('No captured events yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          return EventBubble(event: events[index]);
                        },
                      ),
          ),
          FilterBar(
            value: widget.store.filterText,
            enabled: widget.store.filterEnabled,
            errorText: widget.store.filterError,
            onTextChanged: widget.store.setFilterText,
            onEnabledChanged: widget.store.setFilterEnabled,
          ),
        ],
      ),
    );
  }
}
