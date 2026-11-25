"""Builds drafts/domain3.json by adding the new lesson parts to the existing notes.

The existing notes file is only ever read. Every topic keeps its original fields,
and only studyNotes and practiceQuestions are replaced from the part files.
"""
import json
from pathlib import Path

# The parts folder is wherever this script lives; the project root is two levels up.
PARTS_FOLDER = Path(__file__).resolve().parent
PROJECT_ROOT = PARTS_FOLDER.parent.parent
EXISTING_NOTES = PROJECT_ROOT / "assets" / "content" / "domain3.json"
OUTPUT_FILE = PROJECT_ROOT / "drafts" / "domain3.json"


def load_json(path):
    """Reads one JSON file and returns its parsed contents."""
    return json.loads(path.read_text(encoding="utf-8"))


def deepen_topic(topic):
    """Returns the topic with its new notes and questions, leaving other fields alone."""
    part = load_json(PARTS_FOLDER / f"{topic['id']}.json")
    deepened = dict(topic)
    deepened["studyNotes"] = part["studyNotes"]
    deepened["practiceQuestions"] = part["practiceQuestions"]
    return deepened


def build_domain():
    """Combines the existing domain with every topic part and the review session."""
    domain = load_json(EXISTING_NOTES)
    domain["topics"] = [deepen_topic(topic) for topic in domain["topics"]]
    domain["reviewSession"] = load_json(PARTS_FOLDER / "review.json")["reviewSession"]
    return domain


def main():
    """Writes the merged domain to the output path."""
    text = json.dumps(build_domain(), ensure_ascii=False, indent=2)
    OUTPUT_FILE.write_text(text + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
