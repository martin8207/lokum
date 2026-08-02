import 'package:flutter/material.dart';

import '../../../core/asset_paths.dart';
import '../../../core/services/events_service.dart';
import '../../../shared/models/event.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/theme_toggle.dart';
import '../widgets/archive_event_card.dart';
import '../widgets/event_poster_card.dart';
import '../widgets/featured_event_card.dart';
import 'archive_event_detail_page.dart';
import 'event_detail_page.dart';

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
    final featured = events.where((e) => e.featured).toList();
    final regular = events.where((e) => !e.featured).toList();

    void openDetail(BarEvent event) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final event in featured) ...[
          FeaturedEventCard(
            event: event,
            lang: lang,
            onTap: () => openDetail(event),
          ),
          const SizedBox(height: 16),
        ],
        if (regular.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: regular.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (context, index) => EventPosterCard(
              event: regular[index],
              lang: lang,
              onTap: () => openDetail(regular[index]),
            ),
          ),
      ],
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
    // Задължително сортиране по дата, най-скорошното най-отгоре - независимо
    // от реда в events.json.
    final sorted = [...events]..sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) => ArchiveEventCard(
        event: sorted[index],
        lang: lang,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArchiveEventDetailPage(event: sorted[index]),
            ),
          );
        },
      ),
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
