// expect_lint: linesman
import 'package:linesman_example/import1.dart';
// expect_lint: linesman
import 'package:linesman_example/import2.dart';

// expect_lint: linesman
import 'import3.dart';
// expect_lint: linesman
import 'more_imports/import4.dart';
// expect_lint: linesman
import 'more_imports/more_imports/import5.dart';

/// See linesman.yaml for the rule configuration.

const int result = one + two + three + four + five;
