"""Reports how often the correct option is the shortest, so length never gives the answer away."""
import json
import sys
from pathlib import Path


def is_strictly_shortest(question):
    """Tells whether the correct option is shorter than every other option."""
    lengths = [len(option) for option in question["options"]]
    correct_length = lengths.pop(question["correctIndex"])
    return correct_length < min(lengths)


def length_ratio(question):
    """Returns the correct option's length divided by the longest wrong option's length."""
    lengths = [len(option) for option in question["options"]]
    correct_length = lengths.pop(question["correctIndex"])
    return correct_length / max(lengths)


def main():
    """Prints shortest counts and the weakest length ratios for one domain file."""
    domain = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    for topic in domain["topics"]:
        questions = topic["practiceQuestions"]
        ratios = [round(length_ratio(question), 2) for question in questions]
        print(topic["id"], "correct shortest", sum(map(is_strictly_shortest, questions)), ratios)


if __name__ == "__main__":
    main()
