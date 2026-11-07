import unittest

from evaluate import FIELDS, evaluate


def sample(fields, *, verified=True, split="demo"):
    return {"sample_id": "fixture", "image": "fixture.png", "card_type": "虚构",
            "verified": verified, "split": split, "fields": dict.fromkeys(FIELDS, []) | fields}


def run_demo(truth, parsed, corrected=None):
    result = {"sample_id": "fixture", "ocr_raw_text": "虚构原文",
              "parsed_fields": parsed, "corrected_fields": corrected}
    return evaluate({"samples": [truth]}, {"results": [result]}, split="demo")


class EvaluationTests(unittest.TestCase):
    def test_all_fields_correct_and_multiple_emails_unordered(self):
        fields = {field: ["值"] for field in FIELDS}
        fields["email"] = ["a@example.com", "b@example.com"]
        actual = fields | {"email": ["b@EXAMPLE.COM", "a@example.com"]}
        report = run_demo(sample(fields), actual)["modes"]["parsed_fields"]["overall"]
        self.assertEqual(report["field_accuracy"], 1)
        self.assertEqual(report["matched_values"], 11)

    def test_wrong_name_and_swapped_company_and_title(self):
        truth = {"name": ["林晴"], "company": ["山海科技"], "job_title": ["经理"]}
        actual = {"name": ["林青"], "company": ["经理"], "job_title": ["山海科技"]}
        report = run_demo(sample(truth), actual)["modes"]["parsed_fields"]
        self.assertEqual(report["overall"]["substitution_fields"], 3)
        self.assertEqual(report["overall"]["misclassified_values"], 2)
        self.assertEqual(report["per_sample"]["fixture"]["job_title"]["misclassified_in"],
                         [{"from": "company", "value": "山海科技"}])

    def test_missing_and_invented_website_are_distinct(self):
        missing = run_demo(sample({"website": ["www.example.com"]}), {})["modes"]["parsed_fields"]
        extra = run_demo(sample({}), {"website": ["www.example.com"]})["modes"]["parsed_fields"]
        self.assertEqual(missing["per_field"]["website"]["missing_values"], 1)
        self.assertEqual(missing["overall"]["empty_fields_filled"], 0)
        self.assertEqual(extra["per_field"]["website"]["extra_values"], 1)
        self.assertEqual(extra["overall"]["empty_fields_filled"], 1)

    def test_phone_partial_match_preserves_digits_prefix_and_duplicate_count(self):
        truth = sample({"office": ["+86 010-5555-0123", "+86 010-5555-0124"]})
        parsed = {"office": ["+86 (010) 5555-0123", "+86 010-5555-0123", "010-5555-0124"]}
        row = run_demo(truth, parsed)["modes"]["parsed_fields"]["per_field"]["office"]
        self.assertEqual((row["matched_values"], row["expected_values"]), (1, 2))
        self.assertEqual((row["missing_values"], row["extra_values"]), (1, 2))
        self.assertEqual(row["field_accuracy"], 0)

    def test_corrected_fields_have_separate_totals(self):
        truth = sample({"name": ["林晴"]})
        modes = run_demo(truth, {"name": ["林青"]}, {"name": ["林晴"]})["modes"]
        self.assertEqual(modes["parsed_fields"]["overall"]["field_accuracy"], 0)
        self.assertEqual(modes["corrected_fields"]["overall"]["field_accuracy"], 1)

    def test_unverified_unknown_and_demo_data_are_excluded(self):
        unverified = run_demo(sample({"name": ["未知"]}, verified=False), {"name": ["未知"]})
        self.assertEqual(unverified["eligible_samples"], [])
        unknown = run_demo(sample({"website": None}), {"website": ["www.example.com"]})
        self.assertNotIn("website", unknown["modes"]["parsed_fields"]["per_sample"]["fixture"])
        self.assertEqual(evaluate({"samples": [sample({})]}, {"results": []})["eligible_samples"], [])

    def test_empty_documents_report_no_accuracy_and_bad_format_raises(self):
        report = evaluate({"samples": []}, {"results": []})
        self.assertIsNone(report["modes"]["parsed_fields"]["overall"]["field_accuracy"])
        with self.assertRaisesRegex(ValueError, "results 数组"):
            evaluate({"samples": []}, {"results": {}})
        with self.assertRaisesRegex(ValueError, "字符串数组"):
            run_demo(sample({}), {"name": "错误类型"})


if __name__ == "__main__":
    unittest.main()
