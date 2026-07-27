import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../core/services/events_service.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/theme_toggle.dart';
import '../widgets/event_poster_card.dart';
import '../widgets/past_event_section.dart';

/// Раздел "Събития": предстоящи (постери) и минали (галерия със снимки).
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<Events> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = EventsService.instance.loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLanguage.instance,
      builder: (context, lang, _) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(lang == AppLang.bg ? 'Събития' : 'Events'),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: ThemeToggle(),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: lang == AppLang.bg ? 'Предстоящи' : 'Upcoming'),
                  Tab(text: lang == AppLang.bg ? 'Архив' : 'Past'),
                ],
              ),
            ),
            body: FutureBuilder<Events>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        lang == AppLang.bg
                            ? 'Възникна грешка при зареждане на събитията: ${snapshot.error}'
                            : 'Failed to load events: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final events = snapshot.data!;
                return TabBarView(
                  children: [
                    _UpcomingTab(events: events.upcoming, lang: lang),
                    _PastTab(events: events.past, lang: lang),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  final List<BarEvent> events;
  final AppLang lang;

  const _UpcomingTab({required this.events, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyState(
        icon: Icons.event_available_outlined,
        message: lang == AppLang.bg
            ? 'Няма предстоящи събития в момента.\nСледете ни за новини!'
            : 'No upcoming events right now.\nStay tuned!',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) =>
          EventPosterCard(event: events[index], lang: lang),
    );
  }
}

class _PastTab extends StatelessWidget {
  final List<BarEvent> events;
  final AppLang lang;

  const _PastTab({required this.events, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyState(
        icon: Icons.photo_library_outlined,
        message: lang == AppLang.bg
            ? 'Все още няма архив от събития.'
            : 'No past events yet.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) =>
          PastEventSection(event: events[index], lang: lang),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
