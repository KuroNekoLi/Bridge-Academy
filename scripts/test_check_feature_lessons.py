import unittest

from check_feature_lessons import REQUIRED_SECTIONS, check, is_behavior_source

NOTE = "docs/learning/features/M2_F01_PLAYER_VIEW.md"
INDEX = "docs/learning/INDEX.md"
SOURCE = "packages/bridge_core/lib/src/player_view.dart"
GOOD = "# M2-F01 PlayerView\n- Feature ID：M2-F01\n" + "\n".join(REQUIRED_SECTIONS)


def reading(mapping):
    return lambda path: mapping[path]


class FeatureLessonGateTest(unittest.TestCase):
    def test_source_classification(self):
        self.assertTrue(is_behavior_source(SOURCE))
        self.assertTrue(is_behavior_source("apps/flutter_app/lib/main.dart"))
        self.assertTrue(is_behavior_source("services/game_api/server.py"))
        self.assertFalse(is_behavior_source("packages/bridge_core/test/game_test.dart"))
        self.assertFalse(is_behavior_source("docs/ROADMAP.md"))

    def test_docs_only(self):
        self.assertEqual(check(["README.md"], reading({})), [])

    def test_no_lesson_or_index(self):
        errors = check([SOURCE], reading({}))
        self.assertEqual(len(errors), 2)

    def test_valid_lesson(self):
        files = {NOTE: GOOD, INDEX: "M2-F01 [" + NOTE.split("/")[-1] + "]"}
        self.assertEqual(check([SOURCE, NOTE, INDEX], reading(files)), [])

    def test_missing_sections(self):
        files = {NOTE: "- Feature ID：M2-F01", INDEX: "M2-F01 " + NOTE.split("/")[-1]}
        errors = check([SOURCE, NOTE, INDEX], reading(files))
        self.assertEqual(sum("is missing ##" in e for e in errors),
                         len(REQUIRED_SECTIONS))

    def test_lessons_always_validated_even_docs_only(self):
        files = {NOTE: GOOD, INDEX: "M2-F01 " + NOTE.split("/")[-1]}
        self.assertEqual(check([NOTE, INDEX], reading(files)), [])

    def test_bad_index(self):
        files = {NOTE: GOOD, INDEX: "Other feature"}
        errors = check([SOURCE, NOTE, INDEX], reading(files))
        self.assertTrue(any("Missing M2-F01" in e for e in errors))


if __name__ == "__main__":
    unittest.main()

