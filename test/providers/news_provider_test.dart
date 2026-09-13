import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:power_news_app/providers/news_provider.dart';
import 'package:power_news_app/models/grid_persona.dart';
import 'package:power_news_app/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseService().close();
  });

  group('NewsProvider State & Filtering Tests', () {
    late NewsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = NewsProvider();
    });

    test('Initial filter state is clean and default', () {
      expect(provider.selectedCategory, 'All');
      expect(provider.selectedPlayer, 'All');
      expect(provider.selectedState, 'All States');
      expect(provider.selectedCity, 'All Cities');
      expect(provider.selectedDiscom, 'All DISCOMs');
      expect(provider.currentNavIndex, 0);
      expect(provider.searchQuery, isEmpty);
    });

    test('Updating category filter updates state', () {
      provider.setCategory('transmission');
      expect(provider.selectedCategory, 'transmission');
    });

    test('Updating player filter updates state and clears query', () {
      provider.setPlayerFilter('Siemens');
      expect(provider.selectedPlayer, 'Siemens');
    });

    test('Custom filter addition and removal works correctly', () {
      expect(provider.customFilters.contains('BESS Storage'), false);

      provider.addCustomFilter('BESS Storage');
      expect(provider.customFilters.contains('BESS Storage'), true);

      // Duplicate addition should be ignored
      provider.addCustomFilter('BESS Storage');
      expect(provider.customFilters.where((f) => f == 'BESS Storage').length, 1);

      // Remove custom filter
      provider.removeCustomFilter('BESS Storage');
      expect(provider.customFilters.contains('BESS Storage'), false);
    });

    test('Switching navigation index updates correctly', () {
      provider.setNavIndex(1);
      expect(provider.currentNavIndex, 1);

      provider.setNavIndex(2);
      expect(provider.currentNavIndex, 2);
    });

    test('Clear filters resets all filters to default including persona', () {
      provider.setCategory('renewables');
      provider.setPlayerFilter('NTPC');
      provider.setStateFilter('Rajasthan');

      provider.clearFilters();

      expect(provider.selectedCategory, 'All');
      expect(provider.selectedPlayer, 'All');
      expect(provider.selectedState, 'All States');
      expect(provider.selectedCity, 'All Cities');
      expect(provider.selectedPersona.id, 'all');
      expect(provider.personaOnlyFilter, false);
    });

    test('Persona selection and togglePersonaOnlyFilter update state correctly', () {
      expect(provider.selectedPersona.id, 'all');
      expect(provider.personaOnlyFilter, false);

      provider.setPersona(GridPersona.discom);
      expect(provider.selectedPersona, GridPersona.discom);

      provider.togglePersonaOnlyFilter();
      expect(provider.personaOnlyFilter, true);

      provider.togglePersonaOnlyFilter();
      expect(provider.personaOnlyFilter, false);
    });

    test('markAllNotificationsAsRead and applyNewArticles clear newArticlesCount while preserving notification inbox', () async {
      expect(provider.newArticlesCount, 0);

      // Trigger markAllNotificationsAsRead
      provider.markAllNotificationsAsRead();
      expect(provider.newArticlesCount, 0);

      // Trigger applyNewArticles
      await provider.applyNewArticles();
      expect(provider.newArticlesCount, 0);

      // Trigger clearAllNotifications
      provider.clearAllNotifications();
      expect(provider.newArticlesCount, 0);
      expect(provider.notificationArticles, isEmpty);
    });
  });
}
