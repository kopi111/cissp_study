#!/usr/bin/env python3
"""Merge the Domain 8 lesson parts into drafts/domain8.json, then prove it meets the brief."""
import collections
import json
import pathlib
import re
import sys

PARTS_FOLDER = pathlib.Path(__file__).resolve().parent
EXISTING_NOTES_PATH = PARTS_FOLDER.parent.parent / "assets" / "content" / "domain8.json"
OUTPUT_PATH = PARTS_FOLDER.parent / "domain8.json"

SEGMENT_WORD_RANGE = (300, 400)
TOPIC_WORD_RANGE = (1800, 2400)
REVIEW_WORD_RANGE = (100, 180)
REVIEW_ITEM_RANGE = (8, 12)
SEGMENT_COUNT_RANGE = (5, 6)
PRACTICE_QUESTION_COUNT = 10
OPTION_COUNT = 4
MAXIMUM_LONGEST_CORRECT_PER_TOPIC = 4

# Characters that sound wrong when the app reads the text aloud.
SPOKEN_TEXT_FORBIDDEN = re.compile(r"[$%=&/|<>*]|\bx\b|\be\.g\.|\bi\.e\.")


def load_json(path):
    """Read one JSON file from disk."""
    return json.loads(path.read_text(encoding="utf-8"))


def count_words(text):
    """Count spoken words, leaving out the dash that marks a bullet line."""
    return len([token for token in text.split() if token != "-"])


def merge_topic(existing_topic):
    """Return the topic with its deepened notes and new practice questions."""
    part = load_json(PARTS_FOLDER / f"{existing_topic['id']}.json")
    if part["id"] != existing_topic["id"]:
        raise ValueError(f"Part id does not match topic {existing_topic['id']}")
    merged_topic = dict(existing_topic)
    merged_topic["studyNotes"] = part["studyNotes"]
    merged_topic["practiceQuestions"] = part["practiceQuestions"]
    return merged_topic


def merge_domain(existing_domain):
    """Build the output domain, placing reviewSession just before examQuestions."""
    merged_domain = {}
    for key, value in existing_domain.items():
        if key == "examQuestions":
            merged_domain["reviewSession"] = load_json(PARTS_FOLDER / "review.json")
        merged_domain[key] = value
    merged_domain["topics"] = [merge_topic(topic) for topic in existing_domain["topics"]]
    return merged_domain


def check_within(problems, label, value, allowed_range):
    """Record a problem when a value falls outside its allowed range."""
    low, high = allowed_range
    if not low <= value <= high:
        problems.append(f"{label}: {value} is outside {low} to {high}")


def check_spoken_text(problems, label, text):
    """Record a problem when spoken text holds a symbol that reads badly aloud."""
    for match in SPOKEN_TEXT_FORBIDDEN.finditer(text):
        problems.append(f"{label}: symbol {match.group()!r} in spoken text")


def check_segments(problems, topic):
    """Check segment counts, word limits and spoken style for one topic."""
    segments = topic["studyNotes"]
    check_within(problems, f"{topic['id']} segments", len(segments), SEGMENT_COUNT_RANGE)
    for segment in segments:
        label = f"{topic['id']} '{segment['heading']}'"
        check_within(problems, label, count_words(segment["body"]), SEGMENT_WORD_RANGE)
        check_spoken_text(problems, label, segment["body"])
    total_words = sum(count_words(segment["body"]) for segment in segments)
    check_within(problems, f"{topic['id']} total words", total_words, TOPIC_WORD_RANGE)


def is_correct_option_longest(question):
    """Say whether the correct option is the strictly longest of the four."""
    lengths = [len(option) for option in question["options"]]
    correct_length = lengths[question["correctIndex"]]
    return lengths.count(max(lengths)) == 1 and correct_length == max(lengths)


def check_one_question(problems, label, question):
    """Check the shape of a single practice question."""
    if len(question["options"]) != OPTION_COUNT:
        problems.append(f"{label}: needs {OPTION_COUNT} options")
    if len(set(question["options"])) != len(question["options"]):
        problems.append(f"{label}: repeated option")
    if question["correctIndex"] not in range(OPTION_COUNT):
        problems.append(f"{label}: correctIndex out of range")
    if not question["explanation"].strip():
        problems.append(f"{label}: empty explanation")


def check_answer_spread(problems, topic):
    """Check that correct answers are spread and are not usually the longest."""
    questions = topic["practiceQuestions"]
    spread = collections.Counter(question["correctIndex"] for question in questions)
    if min(spread[index] for index in range(OPTION_COUNT)) < 2:
        problems.append(f"{topic['id']}: uneven correctIndex spread {dict(spread)}")
    longest_correct = sum(is_correct_option_longest(question) for question in questions)
    if longest_correct > MAXIMUM_LONGEST_CORRECT_PER_TOPIC:
        problems.append(f"{topic['id']}: correct option longest {longest_correct} times")


def check_questions(problems, topic):
    """Check every practice question in one topic."""
    questions = topic["practiceQuestions"]
    if len(questions) != PRACTICE_QUESTION_COUNT:
        problems.append(f"{topic['id']}: needs {PRACTICE_QUESTION_COUNT} questions")
    for number, question in enumerate(questions, start=1):
        check_one_question(problems, f"{topic['id']} question {number}", question)
    check_answer_spread(problems, topic)


def check_no_repeated_prompts(problems, domain):
    """Check that new prompts differ from every existing prompt in the domain."""
    existing_prompts = [question["prompt"] for question in domain["examQuestions"]]
    existing_prompts += [topic["question"]["prompt"] for topic in domain["topics"]]
    new_prompts = [
        question["prompt"]
        for topic in domain["topics"]
        for question in topic["practiceQuestions"]
    ]
    if len(set(new_prompts)) != len(new_prompts):
        problems.append("A new practice prompt is repeated")
    for prompt in set(new_prompts) & set(existing_prompts):
        problems.append(f"Prompt copies an existing question: {prompt[:50]}")


def check_review_session(problems, domain):
    """Check the number and length of the review items."""
    items = domain["reviewSession"]
    check_within(problems, "reviewSession items", len(items), REVIEW_ITEM_RANGE)
    for item in items:
        label = f"review '{item['heading']}'"
        check_within(problems, label, count_words(item["body"]), REVIEW_WORD_RANGE)
        check_spoken_text(problems, label, item["body"])


def check_unchanged_fields(problems, domain, existing_domain):
    """Check that everything the brief says to keep is still identical."""
    for key in ("number", "name", "weightPercent", "plainMeaning", "examQuestions"):
        if domain[key] != existing_domain[key]:
            problems.append(f"Domain field changed: {key}")
    kept_topic_fields = (
        "id", "name", "outlineRef", "simpleExplanation",
        "keyTerms", "keyPoints", "memoryHook", "question",
    )
    for topic, existing_topic in zip(domain["topics"], existing_domain["topics"]):
        for key in kept_topic_fields:
            if topic[key] != existing_topic[key]:
                problems.append(f"{topic['id']}: field changed: {key}")


def find_problems(domain, existing_domain):
    """Run every check against the written output."""
    problems = []
    for topic in domain["topics"]:
        check_segments(problems, topic)
        check_questions(problems, topic)
    check_no_repeated_prompts(problems, domain)
    check_review_session(problems, domain)
    check_unchanged_fields(problems, domain, existing_domain)
    return problems


def print_counts(domain):
    """Print the per-topic counts that prove the shape."""
    for topic in domain["topics"]:
        words = [count_words(segment["body"]) for segment in topic["studyNotes"]]
        spread = collections.Counter(q["correctIndex"] for q in topic["practiceQuestions"])
        longest = sum(is_correct_option_longest(q) for q in topic["practiceQuestions"])
        print(topic["id"], words, "total", sum(words),
              "questions", len(topic["practiceQuestions"]),
              "spread", [spread[index] for index in range(OPTION_COUNT)],
              "correct-longest", longest)
    review_words = [count_words(item["body"]) for item in domain["reviewSession"]]
    print("review items", len(review_words), review_words)


def main():
    """Merge the parts, write the output, reread it and report on it."""
    existing_domain = load_json(EXISTING_NOTES_PATH)
    merged_domain = merge_domain(existing_domain)
    OUTPUT_PATH.write_text(
        json.dumps(merged_domain, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    written_domain = load_json(OUTPUT_PATH)
    print_counts(written_domain)
    problems = find_problems(written_domain, existing_domain)
    for problem in problems:
        print("PROBLEM:", problem)
    print("RESULT:", "FAIL" if problems else "PASS")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
