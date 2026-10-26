import unittest
from check_feature_lessons import NOTE, INDEX, check, is_behavior_source

SOURCE = "packages/bridge_core/lib/src/player_view.dart"
GOOD = "# 已完成功能的工程導讀\n## 功能更新時的筆記規格\n## M2-F01｜PlayerView\n"
INDEX_TEXT = "# 已實作功能\n"

def reading(files):
    return lambda path: files[path]

class FeatureLessonGateTest(unittest.TestCase):
    def test_source_classifier(self):
        self.assertTrue(is_behavior_source(SOURCE))
        self.assertFalse(is_behavior_source("packages/bridge_core/test/game_test.dart"))
        self.assertFalse(is_behavior_source("docs/planning/ROADMAP.md"))

    def test_docs_only(self):
        self.assertEqual(check(["README.md"], reading({})), [])

    def test_missing_both(self):
        self.assertEqual(len(check([SOURCE], reading({}))), 2)

    def test_valid_note_and_inventory(self):
        self.assertEqual(check([SOURCE, NOTE, INDEX], reading({NOTE: GOOD, INDEX: INDEX_TEXT})), [])

    def test_bad_note(self):
        problems = check([NOTE], reading({NOTE: "bad"}))
        self.assertGreaterEqual(len(problems), 2)

    def test_bad_inventory(self):
        self.assertTrue(check([INDEX], reading({INDEX: "bad"})))

    def test_docs_note_always_checked(self):
        self.assertEqual(check([NOTE], reading({NOTE: GOOD})), [])

if __name__ == "__main__":
    unittest.main()
