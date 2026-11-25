#!/usr/bin/env python3
"""Merge the Domain 5 part files into drafts/domain5.json, then prove the result meets the brief."""
import copy
import json
import re
import sys
from collections import Counter
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent
SOURCE_NOTES = Path("/home/kopi/projects/cissp_study/assets/content/domain5.json")
OUTPUT_FILE = Path("/home/kopi/projects/cissp_study/drafts/domain5.json")
TOPIC_IDS = [f"T{number}" for number in range(40, 47)]

# Text limits taken straight from the writing brief.
SEGMENT_WORDS = (300, 400)
TOPIC_WORDS = (1800, 2400)
REVIEW_ITEM_WORDS = (100, 180)
REVIEW_ITEM_COUNT = (8, 12)
# Characters that sound wrong when the app reads the text aloud.
SPOKEN_TEXT_BANNED = re.compile(r"[%=&/+*]")


def read_json(path):
    # Every part file is plain JSON, so one reader serves them all.
    with path.open(encoding="utf-8") as json_file:
        return json.load(json_file)


def spoken_word_count(body):
    # A bullet marker on its own is not a spoken word, so it is not counted.
    return len([word for word in body.split() if word != "-"])


def build_domain():
    # Start from the existing notes, so every field the brief protects stays identical.
    domain = copy.deepcopy(read_json(SOURCE_NOTES))
    for topic in domain["topics"]:
        part = read_json(PARTS_FOLDER / f"{topic['id']}.json")
        topic["studyNotes"] = part["studyNotes"]
        topic["practiceQuestions"] = part["practiceQuestions"]
    domain["reviewSession"] = read_json(PARTS_FOLDER / "reviewSession.json")
    return domain


def in_range(value, limits):
    # True when the value sits inside the inclusive low and high limits.
    return limits[0] <= value <= limits[1]


def check_spoken_text(label, text, problems):
    # Flag characters that a text-to-speech voice would read badly.
    if SPOKEN_TEXT_BANNED.search(text):
        problems.append(f"{label}: symbol that sounds wrong aloud in {text[:70]!r}")


def check_segments(topic, problems):
    # Each topic needs 5 or 6 segments of the right length, and the right total.
    segments = topic["studyNotes"]
    if len(segments) not in (5, 6):
        problems.append(f"{topic['id']}: {len(segments)} segments")
    total_words = 0
    for segment in segments:
        words = spoken_word_count(segment["body"])
        total_words += words
        if not in_range(words, SEGMENT_WORDS):
            problems.append(f"{topic['id']}: segment '{segment['heading']}' has {words} words")
        check_spoken_text(topic["id"], segment["body"], problems)
    if not in_range(total_words, TOPIC_WORDS):
        problems.append(f"{topic['id']}: {total_words} total words")
    return total_words


def check_question(topic_id, question, known_prompts, problems):
    # A question needs 4 distinct options, a valid key and a prompt not used elsewhere.
    options = question["options"]
    if len(options) != 4 or len(set(options)) != 4:
        problems.append(f"{topic_id}: bad options in {question['prompt'][:50]!r}")
    if question["correctIndex"] not in range(4):
        problems.append(f"{topic_id}: bad correctIndex in {question['prompt'][:50]!r}")
    if question["prompt"] in known_prompts:
        problems.append(f"{topic_id}: repeated prompt {question['prompt'][:50]!r}")
    known_prompts.add(question["prompt"])
    for text in [question["prompt"], question["explanation"], *options]:
        check_spoken_text(topic_id, text, problems)


def correct_is_longest(question):
    # Counts as longest only when no other option is as long as the correct one.
    lengths = [len(option) for option in question["options"]]
    correct_length = lengths[question["correctIndex"]]
    return lengths.count(max(lengths)) == 1 and correct_length == max(lengths)


def check_questions(topic, known_prompts, problems):
    # Exactly 10 questions, keys spread across all positions, correct rarely longest.
    questions = topic["practiceQuestions"]
    if len(questions) != 10:
        problems.append(f"{topic['id']}: {len(questions)} questions")
    for question in questions:
        check_question(topic["id"], question, known_prompts, problems)
    key_counts = Counter(question["correctIndex"] for question in questions)
    if any(key_counts[position] < 2 or key_counts[position] > 3 for position in range(4)):
        problems.append(f"{topic['id']}: uneven answer key {dict(key_counts)}")
    longest_count = sum(correct_is_longest(question) for question in questions)
    if longest_count > 3:
        problems.append(f"{topic['id']}: correct option longest {longest_count} times")
    return key_counts, longest_count


def check_review(domain, problems):
    # The recap must have 8 to 12 items, each of the right length.
    items = domain["reviewSession"]
    if not in_range(len(items), REVIEW_ITEM_COUNT):
        problems.append(f"reviewSession: {len(items)} items")
    for item in items:
        words = spoken_word_count(item["body"])
        if not in_range(words, REVIEW_ITEM_WORDS):
            problems.append(f"reviewSession: '{item['heading']}' has {words} words")
        check_spoken_text("reviewSession", item["body"], problems)
    return len(items)


def check_protected_fields(domain, problems):
    # Fields the brief says to keep must match the source notes exactly.
    source = read_json(SOURCE_NOTES)
    for field in ("number", "name", "weightPercent", "plainMeaning", "examQuestions"):
        if domain[field] != source[field]:
            problems.append(f"domain field changed: {field}")
    kept_fields = ("id", "name", "outlineRef", "simpleExplanation", "keyTerms",
                   "keyPoints", "memoryHook", "question")
    for new_topic, old_topic in zip(domain["topics"], source["topics"]):
        for field in kept_fields:
            if new_topic[field] != old_topic[field]:
                problems.append(f"{old_topic['id']}: field changed: {field}")


def existing_prompts(domain):
    # Prompts already in the notes, so new questions cannot repeat them.
    prompts = {question["prompt"] for question in domain["examQuestions"]}
    prompts.update(topic["question"]["prompt"] for topic in domain["topics"])
    return prompts


def verify(domain):
    # Run every check, print per-topic counts, and return the list of problems.
    problems = []
    known_prompts = existing_prompts(domain)
    if [topic["id"] for topic in domain["topics"]] != TOPIC_IDS:
        problems.append("topic ids or order differ from T40 to T46")
    for topic in domain["topics"]:
        total_words = check_segments(topic, problems)
        key_counts, longest_count = check_questions(topic, known_prompts, problems)
        segment_words = [spoken_word_count(segment["body"]) for segment in topic["studyNotes"]]
        print(topic["id"], "segments", segment_words, "total", total_words,
              "keys", dict(sorted(key_counts.items())), "correct-longest", longest_count)
    review_count = check_review(domain, problems)
    print("reviewSession items", review_count,
          "words", [spoken_word_count(item["body"]) for item in domain["reviewSession"]])
    check_protected_fields(domain, problems)
    return problems


def main():
    # Write the merged file, reload it from disk to prove it parses, then verify it.
    domain = build_domain()
    OUTPUT_FILE.write_text(json.dumps(domain, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    problems = verify(read_json(OUTPUT_FILE))
    for problem in problems:
        print("PROBLEM:", problem)
    print("PROBLEMS:", len(problems))
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
