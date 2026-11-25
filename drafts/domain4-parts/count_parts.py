"""Prints the word count of every segment in each part file, so long or short ones can be fixed before merging."""
import json
import sys
from pathlib import Path
PARTS_FOLDER = Path(__file__).resolve().parent
# Counts spoken words only, so a bullet's leading dash is not counted.
def count_words(text):
    return len([token for token in text.split() if token != "-"])
# Goes through each topic part named on the command line, or all of them.
names = sys.argv[1:] or sorted(p.stem for p in PARTS_FOLDER.glob("T*.json"))
for name in names:
    part = json.loads((PARTS_FOLDER / f"{name}.json").read_text(encoding="utf-8"))
    words = [count_words(s["body"]) for s in part["studyNotes"]]
    positions = [sum(q["correctIndex"] == i for q in part["practiceQuestions"]) for i in range(4)]
    longest = sum(len(q["options"][q["correctIndex"]]) > max(len(o) for j, o in enumerate(q["options"]) if j != q["correctIndex"]) for q in part["practiceQuestions"])
    print(name, words, "total", sum(words), "questions", len(part["practiceQuestions"]), "positions", positions, "longest", longest)
