"""Reports word counts and question spread for each finished part file.

Run it while writing, to see which segments need more or fewer words.
"""
import collections
import json
import re
import sys
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent
BAD_SPOKEN_SYMBOLS = re.compile(r"[$%=+×*/&\"]| - |\bvs\b|\be\.g\.")


def count_words(text):
    """Counts spoken words, so a bullet's leading dash is not counted as one."""
    return len([token for token in text.split() if token != "-"])


def is_correct_longest(question):
    """Tells whether the correct option is strictly longer than the others."""
    lengths = [len(option) for option in question["options"]]
    correct_length = lengths.pop(question["correctIndex"])
    return correct_length > max(lengths)


def report_topic(path):
    """Prints one topic's counts and flags any segment outside the limits."""
    part = json.loads(path.read_text(encoding="utf-8"))
    words = [count_words(segment["body"]) for segment in part["studyNotes"]]
    questions = part["practiceQuestions"]
    positions = collections.Counter(question["correctIndex"] for question in questions)
    longest = sum(is_correct_longest(question) for question in questions)
    print(path.stem, words, "total", sum(words), "questions", len(questions),
          "positions", [positions[index] for index in range(4)], "longest", longest)
    for segment in part["studyNotes"]:
        found = BAD_SPOKEN_SYMBOLS.search(segment["body"])
        if found:
            print("  SYMBOL", repr(found.group()), "in", segment["heading"])
        if not 300 <= count_words(segment["body"]) <= 400:
            print("  LENGTH", count_words(segment["body"]), "in", segment["heading"])


def main():
    """Checks the part files named on the command line, or every topic file."""
    names = sys.argv[1:] or sorted(path.stem for path in PARTS_FOLDER.glob("T*.json"))
    for name in names:
        report_topic(PARTS_FOLDER / f"{name}.json")


if __name__ == "__main__":
    main()
