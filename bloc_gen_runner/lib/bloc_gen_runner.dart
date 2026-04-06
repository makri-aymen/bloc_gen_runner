library;

import 'package:bloc_gen_runner/src/bloc_events_generator.dart';
import 'package:bloc_gen_runner/src/bloc_generator_config.dart';
import 'package:bloc_gen_runner/src/bloc_states_generator.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_gen/source_gen.dart';

export 'src/bloc_events_generator.dart';

Builder blocGeneratorBuilder(BuilderOptions options) {
  final config = BlocGeneratorConfig.fromOptions(options);
  return SharedPartBuilder(
    [
      BlocEventsGenerator(config),
      BlocStatesGenerator(config),
    ],
    'bloc_gen_runner',
    writeDescriptions: false,
    formatOutput: (value, version) => DartFormatter(
      languageVersion: Version(3, 11, 4),
    ).format(value),
  );
}
