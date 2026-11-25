"""One-off corrections after the first draft: wording, spoken units, and even answer positions."""
import json
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent

# Exact text swaps, one file at a time. Each old text must exist or the script stops.
TEXT_SWAPS = {
    "T39": [
        (" Most people never see it, and yet almost everything depends upon it.", ""),
        ("There is real arithmetic in this. A query ID has 16 bits, and so 65,536 possible values. Adding a random port multiplies the guesses by roughly another 60,000.",
         "A query ID has 16 bits, which gives 65,536 possible values. Adding a random port makes guessing far harder."),
    ],
    "T36": [("SOCKS, a common proxy protocol, is the example.", "SOCKS, short for Socket Secure, a common proxy protocol, is the example.")],
    "T34": [
        ("It used a cipher called RC4 with", "It used a cipher called RC4, short for Rivest Cipher 4, with"),
        ("GHz is gigahertz, the radio frequency, and Mbps is megabits per second, the speed.", "Frequency is measured in gigahertz, and speed in megabits per second."),
        (" Mbps", " megabits per second"),
        (" GHz", " gigahertz"),
    ],
    "T33": [("Another is VLAN hopping, where extra tags are added to a frame to reach a separate virtual network.",
             "Another is VLAN hopping, where VLAN means Virtual Local Area Network, and extra tags are added to a frame to reach a separate virtual network.")],
    "T37": [
        ("Cables come in categories, and the exam may give you distance limits. Gbps means gigabits per second.", "Cables come in categories, and the exam may give you distance limits."),
        ("Cat5e: 1 Gbps over", "Cat5e: 1 gigabit per second over"),
        ("10 Gbps over", "10 gigabits per second over"),
        ("run ordinary PVC-jacketed cable above", "run ordinary cable above"),
    ],
    "T35": [
        ("Making sure that each switch has a matching paint colour", "Keeping the existing VLAN numbers unchanged after the move"),
        ("Reducing the number of staff trained on network tools", "Buying the new switches from more than one vendor"),
    ],
    "T38": [
        ("Whether the new phones match the colour of the office furniture", "Whether call quality will match that of the old phones"),
        ("Whether staff will enjoy the new phone menu system", "Whether the new phones will cost less to maintain"),
        ("Whether the voice network can be given a more memorable name", "Whether staff will need training on the new phone menus"),
        ("The other options are matters of preference with no safety effect.", "Call quality is tempting because it matters to the business, but a failed emergency call could cost a life."),
        ("The login name is easy for people to remember", "The engineers connect from several different locations"),
        ("The vendor's engineers may forget the shared login", "The login does not expire at the end of each year"),
    ],
}

# Moves the correct option to a new position: (topic, question number from 1, new index).
ANSWER_MOVES = [("T37", 5, 3), ("T37", 6, 2), ("T37", 9, 2), ("T37", 10, 3),
                ("T34", 10, 3), ("T36", 9, 3), ("T36", 3, 0)]


def apply_text_swaps(topic, swaps):
    """Replaces each old text in the raw file, stopping if any is missing."""
    path = PARTS_FOLDER / f"{topic}.json"
    text = path.read_text(encoding="utf-8")
    for old, new in swaps:
        if old not in text:
            raise ValueError(f"{topic}: not found: {old}")
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")


def move_answer(topic, question_number, new_index):
    """Swaps the correct option into new_index and updates correctIndex to match."""
    path = PARTS_FOLDER / f"{topic}.json"
    part = json.loads(path.read_text(encoding="utf-8"))
    question = part["practiceQuestions"][question_number - 1]
    options, old_index = question["options"], question["correctIndex"]
    options[old_index], options[new_index] = options[new_index], options[old_index]
    question["correctIndex"] = new_index
    path.write_text(json.dumps(part, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    """Applies all the swaps first, then all the answer moves."""
    for topic, swaps in TEXT_SWAPS.items():
        apply_text_swaps(topic, swaps)
    for topic, question_number, new_index in ANSWER_MOVES:
        move_answer(topic, question_number, new_index)


if __name__ == "__main__":
    main()
