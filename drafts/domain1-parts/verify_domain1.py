"""Proves that drafts/domain1.json meets the writing brief, and prints any failures.

Exits with status 1 if a hard rule is broken. Softer quality signals, such as how
often the correct option is the longest, are printed so a person can judge them.
"""
import collections
import json
import re
import sys
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent
PROJECT_ROOT = PARTS_FOLDER.parent.parent
EXISTING_NOTES = PROJECT_ROOT / "assets" / "content" / "domain1.json"
OUTPUT_FILE = PROJECT_ROOT / "drafts" / "domain1.json"

KEPT_TOPIC_FIELDS = ["id", "name", "outlineRef", "simpleExplanation", "keyTerms",
                     "keyPoints", "memoryHook", "question"]
KEPT_DOMAIN_FIELDS = ["number", "name", "weightPercent", "plainMeaning", "examQuestions"]

# Symbols that a text-to-speech voice reads badly. A hyphen inside a word is fine.
BAD_SPOKEN_SYMBOLS = re.compile(r"[$%=+×*/&]| - |\bvs\b|\be\.g\.")
OPTION_LETTER_PREFIX = re.compile(r"^\(?[A-Da-d][.)]\s")


def count_words(text):
    """Counts spoken words, so a bullet's leading dash is not counted as one."""
    return len([token for token in text.split() if token != "-"])


def segment_problems(topic):
    """Checks the number and length of a topic's study segments."""
    problems = []
    segments = topic["studyNotes"]
    if len(segments) not in (5, 6):
        problems.append(f"{topic['id']}: {len(segments)} segments")
    for segment in segments:
        words = count_words(segment["body"])
        if not 300 <= words <= 400:
            problems.append(f"{topic['id']}: '{segment['heading']}' has {words} words")
        if BAD_SPOKEN_SYMBOLS.search(segment["body"]):
            found = BAD_SPOKEN_SYMBOLS.search(segment["body"]).group()
            problems.append(f"{topic['id']}: '{segment['heading']}' has symbol {found!r}")
    total = sum(count_words(segment["body"]) for segment in segments)
    if not 1800 <= total <= 2400:
        problems.append(f"{topic['id']}: total {total} words")
    return problems


def question_problems(topic, known_prompts):
    """Checks one topic's practice questions for shape and for duplicates."""
    problems = []
    questions = topic["practiceQuestions"]
    if len(questions) != 10:
        problems.append(f"{topic['id']}: {len(questions)} practice questions")
    for question in questions:
        label = f"{topic['id']}: '{question['prompt'][:40]}'"
        if len(question["options"]) != 4 or len(set(question["options"])) != 4:
            problems.append(f"{label} does not have 4 distinct options")
        if question["correctIndex"] not in range(4):
            problems.append(f"{label} has a bad correctIndex")
        if any(OPTION_LETTER_PREFIX.match(option) for option in question["options"]):
            problems.append(f"{label} has a lettered option")
        if question["prompt"] in known_prompts:
            problems.append(f"{label} repeats an earlier prompt")
        known_prompts.add(question["prompt"])
    return problems


def kept_field_problems(domain, original):
    """Confirms that everything the brief says to keep is byte-for-byte unchanged."""
    problems = [f"domain field {field} changed" for field in KEPT_DOMAIN_FIELDS
                if domain[field] != original[field]]
    for topic, original_topic in zip(domain["topics"], original["topics"]):
        problems += [f"{topic['id']}: field {field} changed" for field in KEPT_TOPIC_FIELDS
                     if topic[field] != original_topic[field]]
    return problems


def review_problems(domain):
    """Checks the number and length of the review session items."""
    items = domain["reviewSession"]
    problems = [] if 8 <= len(items) <= 12 else [f"review has {len(items)} items"]
    for item in items:
        words = count_words(item["body"])
        if not 100 <= words <= 180:
            problems.append(f"review '{item['heading']}' has {words} words")
        if BAD_SPOKEN_SYMBOLS.search(item["body"]):
            problems.append(f"review '{item['heading']}' has a symbol")
    return problems


def correct_is_strictly_longest(question):
    """Tells whether the correct option is longer than every other option."""
    lengths = [len(option) for option in question["options"]]
    correct_length = lengths.pop(question["correctIndex"])
    return correct_length > max(lengths)


def print_counts(domain):
    """Prints the per-topic counts and the answer-position spread."""
    spread = collections.Counter()
    for topic in domain["topics"]:
        questions = topic["practiceQuestions"]
        words = [count_words(segment["body"]) for segment in topic["studyNotes"]]
        positions = collections.Counter(q["correctIndex"] for q in questions)
        longest = sum(correct_is_strictly_longest(q) for q in questions)
        spread.update(positions)
        print(topic["id"], "segments", len(words), "words", sum(words),
              f"range {min(words)}-{max(words)}", "questions", len(questions),
              "positions", [positions[i] for i in range(4)], "correct longest", longest)
    print("answer positions overall", [spread[i] for i in range(4)])
    print("review items", len(domain["reviewSession"]))


def main():
    """Runs every check, prints the results and sets the exit status."""
    domain = json.loads(OUTPUT_FILE.read_text(encoding="utf-8"))
    original = json.loads(EXISTING_NOTES.read_text(encoding="utf-8"))
    known_prompts = {topic["question"]["prompt"] for topic in original["topics"]}
    known_prompts |= {question["prompt"] for question in original["examQuestions"]}

    problems = kept_field_problems(domain, original) + review_problems(domain)
    for topic in domain["topics"]:
        problems += segment_problems(topic) + question_problems(topic, known_prompts)

    print_counts(domain)
    for problem in problems:
        print("PROBLEM", problem)
    print("PASS" if not problems else f"FAIL with {len(problems)} problems")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
