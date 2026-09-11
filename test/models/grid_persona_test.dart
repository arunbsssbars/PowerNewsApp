import 'package:flutter_test/flutter_test.dart';
import 'package:power_news_app/models/grid_persona.dart';

void main() {
  group('GridPersona Model & Relevance Tests', () {
    test('Calculates high relevance for DISCOM persona on smart metering news', () {
      const persona = GridPersona.discom;
      final score = persona.calculateRelevance(
        'UPPCL deploys 500,000 smart prepaid meters across Lucknow',
        'The distribution utility aims to reduce AT&C losses below 12% under the RDSS scheme.',
        'Distribution & DISCOMs',
        'UPPCL',
      );

      expect(score, greaterThan(60.0));
    });

    test('Calculates low relevance for DISCOM persona on wind turbine order', () {
      const persona = GridPersona.discom;
      final score = persona.calculateRelevance(
        'Inox Wind bags 100 MW turbine order',
        'Turnkey EPC supply in Gujarat.',
        'Thermal & Hydro Power',
        'Inox Wind',
      );

      expect(score, lessThan(40.0));
    });

    test('Calculates high relevance for Transmission persona on 765kV substation', () {
      const persona = GridPersona.transmission;
      final score = persona.calculateRelevance(
        'POWERGRID commissions 765kV transmission bay and substation',
        'The HVDC link enhances inter-regional evacuation capacity with SCADA automation.',
        'Transmission & Grid',
        'POWERGRID',
      );

      expect(score, greaterThan(60.0));
    });

    test('All persona returns 100% score for all articles', () {
      const persona = GridPersona.all;
      final score = persona.calculateRelevance('Any news', 'Any summary', 'Any', null);
      expect(score, equals(100.0));
    });

    test('fromId correctly parses string IDs and defaults to all', () {
      expect(GridPersona.fromId('discom'), equals(GridPersona.discom));
      expect(GridPersona.fromId('transmission'), equals(GridPersona.transmission));
      expect(GridPersona.fromId('renewables'), equals(GridPersona.renewables));
      expect(GridPersona.fromId('oem'), equals(GridPersona.oem));
      expect(GridPersona.fromId('policy'), equals(GridPersona.policy));
      expect(GridPersona.fromId('unknown'), equals(GridPersona.all));
      expect(GridPersona.fromId(null), equals(GridPersona.all));
    });
  });
}
