// expect_lint: linesman_lint
import 'package:linesman_lint_example/import1.dart';
// expect_lint: linesman_lint
import 'package:linesman_lint_example/import2.dart';

// expect_lint: linesman_lint
import 'import3.dart';
// expect_lint: linesman_lint
import 'more_imports/import4.dart';
// expect_lint: linesman_lint
import 'more_imports/more_imports/import5.dart';

/// See analysis_options.yaml for the rule configuration.

const int result = one + two + three + four + five;
