"""Score captured fields against a frozen, independently reviewed ground truth."""
import argparse
from collections import Counter
import csv
import json
from pathlib import Path
import re
import sys
import unicodedata

FIELDS = ("name", "company", "job_title", "mobile", "office", "fax",
          "other_phone", "email", "website", "address")
PHONE = ("mobile", "office", "fax", "other_phone")
MODES = ("parsed_fields", "corrected_fields", "reference_parsed_fields")
PLACEHOLDERS = {"未识别", "姓名未识别", "未确定"}


def normalize(field, value):
    value = unicodedata.normalize("NFC", value).strip()
    if field in PHONE:
        # Preserve every digit, leading zero, international prefix, and extension text.
        value = value.translate(str.maketrans("０１２３４５６７８９＋（）－．", "0123456789+()-."))
        return re.sub(r"[\s().\-–—]", "", value)
    if field == "email":
        local, sep, domain = value.rpartition("@")
        return local + sep + domain.lower()
    if field == "website":
        match = re.fullmatch(r"(?:(https?)://)?([^/?#]+)(.*)", value, flags=re.I)
        if match:
            scheme, host, suffix = match.groups()
            return (scheme or "https").lower() + "://" + host.lower() + (suffix or "/")
        return value
    return " ".join(value.split()).casefold()


def validate_fields(value, where, *, truth=False):
    if not isinstance(value, dict) or set(value) - set(FIELDS):
        raise ValueError(f"{where} 必须是仅含约定字段的对象")
    if truth and set(value) != set(FIELDS):
        raise ValueError(f"{where} 必须明确列出每个字段（[] 表示不存在，null 表示未知）")
    for field, entries in value.items():
        if truth and entries is None:
            continue
        if not isinstance(entries, list) or any(
            not isinstance(entry, str) or not normalize(field, entry)
            or entry.strip() in PLACEHOLDERS for entry in entries
        ):
            raise ValueError(f"{where}.{field} 必须为非空值的字符串数组，不能含 UI 占位词")


def index_rows(document, key):
    if not isinstance(document, dict) or not isinstance(document.get(key), list):
        raise ValueError(f"需要顶层对象和 {key} 数组")
    rows = {}
    for row in document[key]:
        if not isinstance(row, dict):
            raise ValueError(f"{key} 的每项必须是对象")
        sample_id = row.get("sample_id")
        if not isinstance(sample_id, str) or not sample_id or sample_id.strip() != sample_id or sample_id in rows:
            raise ValueError(f"{key} 的 sample_id 为空、不规范或重复：{sample_id!r}")
        rows[sample_id] = row
    return rows


def compare(truth, predicted):
    rows = {}
    for field in FIELDS:
        if truth[field] is None:
            continue
        expected = Counter(normalize(field, v) for v in truth[field])
        actual = Counter(normalize(field, v) for v in predicted.get(field, []))
        missing, extra = expected - actual, actual - expected
        rows[field] = {
            "expected": truth[field], "actual": predicted.get(field, []),
            "matched": sum((expected & actual).values()),
            "expected_count": sum(expected.values()), "exact": expected == actual,
            "missing": list(missing.elements()), "extra": list(extra.elements()),
            "misclassified_in": [],
        }

    # Pair only unmatched values in related fields. Consume each occurrence once.
    for family in (("name", "company", "job_title"), PHONE):
        available = {f: Counter(rows[f]["extra"]) for f in family if f in rows}
        for source in family:
            if source not in rows:
                continue
            for value in rows[source]["missing"]:
                for target in family:
                    if target != source and target in available and available[target][value]:
                        available[target][value] -= 1
                        rows[target]["misclassified_in"].append({"from": source, "value": value})
                        break
    return rows


def tally(rows):
    return {
        "evaluated_fields": len(rows),
        "exact_fields": sum(row["exact"] for row in rows),
        "expected_values": sum(row["expected_count"] for row in rows),
        "matched_values": sum(row["matched"] for row in rows),
        "missing_values": sum(len(row["missing"]) for row in rows),
        "extra_values": sum(len(row["extra"]) for row in rows),
        "empty_fields_filled": sum(not row["expected_count"] and bool(row["extra"]) for row in rows),
        "substitution_fields": sum(bool(row["missing"] and row["extra"]) for row in rows),
        "misclassified_values": sum(len(row["misclassified_in"]) for row in rows),
    }


def summarize(rows):
    totals = tally(rows)
    present = [row for row in rows if row["expected_count"]]
    totals["populated_fields"] = len(present)
    totals["exact_populated_fields"] = sum(row["exact"] for row in present)
    totals["field_accuracy"] = totals["exact_populated_fields"] / len(present) if present else None
    totals["value_recall"] = (
        totals["matched_values"] / totals["expected_values"] if totals["expected_values"] else None
    )
    return totals


def evaluate(truth_document, result_document, split="formal"):
    truths = index_rows(truth_document, "samples")
    results = index_rows(result_document, "results")
    for sample_id, row in truths.items():
        if type(row.get("verified")) is not bool or row.get("split") not in ("pilot", "formal", "demo"):
            raise ValueError(f"{sample_id} 缺少有效 verified/split")
        for key in ("image", "card_type"):
            if not isinstance(row.get(key), str) or not row[key].strip():
                raise ValueError(f"{sample_id}.{key} 必须是非空字符串")
        validate_fields(row.get("fields"), sample_id, truth=True)
    for sample_id, row in results.items():
        if sample_id not in truths:
            raise ValueError(f"结果含未知样本：{sample_id}")
        if not isinstance(row.get("ocr_raw_text"), str):
            raise ValueError(f"{sample_id}.ocr_raw_text 必须是字符串")
        for mode in MODES:
            if row.get(mode) is not None:
                validate_fields(row[mode], f"{sample_id}.{mode}")

    eligible = [i for i, row in truths.items() if row["split"] == split and row["verified"]
                and any(value is not None for value in row["fields"].values())]
    report = {"split": split, "eligible_samples": eligible, "modes": {}}
    for mode in MODES:
        comparisons = {}
        for sample_id in eligible:
            prediction = results.get(sample_id, {}).get(mode)
            if prediction is not None:
                comparisons[sample_id] = compare(truths[sample_id]["fields"], prediction)
        by_field = {field: summarize([rows[field] for rows in comparisons.values() if field in rows])
                    for field in FIELDS}
        report["modes"][mode] = {
            "uncollected_samples": [i for i in eligible if i not in comparisons],
            "per_sample": comparisons,
            "per_field": by_field,
            "overall": summarize([row for rows in comparisons.values() for row in rows.values()]),
        }
    return report


def write_csv(path, report):
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["split", "mode", "scope", "sample_id", "field", "comparison_json"])
        for mode, result in report["modes"].items():
            writer.writerow([report["split"], mode, "overall", "", "", json.dumps(result["overall"])])
            for field, summary in result["per_field"].items():
                writer.writerow([report["split"], mode, "field", "", field, json.dumps(summary)])
            for sample_id, rows in result["per_sample"].items():
                for field, row in rows.items():
                    writer.writerow([report["split"], mode, "sample", sample_id, field,
                                     json.dumps(row, ensure_ascii=False)])


def main():
    directory = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--truth", type=Path, default=directory / "ground_truth.json")
    parser.add_argument("--results", type=Path, default=directory / "recognition_results.json")
    parser.add_argument("--split", choices=("formal", "pilot", "demo"), default="formal")
    parser.add_argument("--csv", type=Path, help="CSV 输出路径")
    args = parser.parse_args()
    try:
        if args.csv and args.csv.resolve() in {args.truth.resolve(), args.results.resolve()}:
            raise ValueError("CSV 输出不能覆盖输入文件")
        truth = json.loads(args.truth.read_text(encoding="utf-8"))
        results = json.loads(args.results.read_text(encoding="utf-8"))
        report = evaluate(truth, results, args.split)
        if args.csv:
            write_csv(args.csv, report)
    except (OSError, ValueError) as error:
        parser.exit(2, f"评估输入或输出错误：{error}\n")
    if not any(mode["per_sample"] for mode in report["modes"].values()):
        print("没有可计分结果，请检查数据分组、已核对真值与采集记录。", file=sys.stderr)
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
