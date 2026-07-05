import 'package:flutter_test/flutter_test.dart';

import 'package:couple_app/config/supabase_config.dart';

void main() {
  test('Supabase config is not configured without dart defines', () {
    expect(SupabaseConfig.isConfigured, isFalse);
  });
}
