"""Prints word counts and answer-position spread for each topic part written so far."""
import collections
import glob
import json
import re
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent
BAD_SPOKEN_SYMBOLS = re.compile(r"[$%=+×*/&]| - |\bvs\b|\be\.g\.")


def count_words(text):
    """Counts spoken words, leaving out each bullet's leading dash."""
    return len([token for token in text.split() if token != "-"])


def report_topic(path):
    """Prints one topic's segment lengths, answer spread and any spoken-symbol hits."""
    part = json.loads(Path(path).read_text(encoding="utf-8"))
    words = [count_words(segment["body"]) for segment in part["studyNotes"]]
    questions = part["practiceQuestions"]
    spread = collections.Counter(question["correctIndex"] for question in questions)
    longest = 0
    for question in questions:
        lengths = [len(option) for option in question["options"]]
        correct = lengths.pop(question["correctIndex"])
        longest += correct > max(lengths)
    flag = "" if all(300 <= w <= 400 for w in words) and 1800 <= sum(words) <= 2400 else "  <-- LENGTH"
    print(part["id"], words, sum(words), "q", len(questions), [spread[i] for i in range(4)], "longest", longest, flag)
    for segment in part["studyNotes"]:
        for match in BAD_SPOKEN_SYMBOLS.finditer(segment["body"]):
            print("   symbol", repr(match.group()), "in", segment["heading"])


for file_path in sorted(glob.glob(str(PARTS_FOLDER / "T*.json"))):
    report_topic(file_path)
