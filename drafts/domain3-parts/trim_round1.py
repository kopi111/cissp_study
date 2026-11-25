"""Removes named sentences from topic parts, to bring segments inside the word limits."""
import json
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent

REMOVALS = {
    "T22": [
        " It is an idea, and not a product.",
        " A forgotten maintenance interface is a typical example.",
        " The developer who wrote it has left.",
        " So the old excuse, that encryption will slow us down, is much weaker today.",
    ],
    "T23": [
        " The door at home never moves.",
        " Experts spend years checking the well known libraries.",
        " Here we are interested in where such systems are weak.",
        " Slowly, a secret leaves the system.",
    ],
    "T24": [
        " A store may hold images that are out of date, or that have been deliberately poisoned.",
        " Sensible limits on the number of requests also help.",
        " Peer-to-peer systems and blockchains are examples of distributed design.",
        " You might have one in your washing machine.",
        " Data moved in and out should also be checked, because these systems often hold valuable research.",
    ],
}


def remove_sentences(topic_id, sentences):
    """Deletes each sentence from the topic's notes, and fails loudly if one is missing."""
    path = PARTS_FOLDER / f"{topic_id}.json"
    part = json.loads(path.read_text(encoding="utf-8"))
    for sentence in sentences:
        matched = [segment for segment in part["studyNotes"] if sentence in segment["body"]]
        if len(matched) != 1:
            raise ValueError(f"{topic_id}: {sentence!r} matched {len(matched)} segments")
        matched[0]["body"] = matched[0]["body"].replace(sentence, "", 1)
    path.write_text(json.dumps(part, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


for topic, removal_list in REMOVALS.items():
    remove_sentences(topic, removal_list)
