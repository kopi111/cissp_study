"""Third pass: word-limit trims, fact and acronym fixes, and one answer-position swap."""
import json
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent

BODY_EDITS = {
    "T21": [
        ("Its Special Publication 800-53 lists controls and offers low, moderate and high baselines.",
         "Its Special Publication 800-53 lists controls, and a companion publication, 800-53B, offers low, moderate and high baselines."),
        ("The older European scheme was called ITSEC.",
         "The older European scheme was the Information Technology Security Evaluation Criteria, or ITSEC."),
    ],
    "T23": [
        ("and MD5, a method for fingerprinting data,", "and MD5, the Message Digest 5 method for fingerprinting data,"),
    ],
    "T25": [
        ("DES and AES are block ciphers, and we will study them shortly.",
         "DES, the Data Encryption Standard, and AES, the Advanced Encryption Standard, are block ciphers, and we will study them shortly."),
        (" Governments have used it for very sensitive messages.", ""),
        (" Anyone holding that key can open the door.", ""),
    ],
    "T26": [
        ("Then the whole page is protected with AES, the fast symmetric standard.",
         "Then the whole page is protected with AES, the Advanced Encryption Standard, which is fast and symmetric."),
    ],
    "T28": [
        ("short hashes such as MD5, at 128 bits,", "short hashes such as MD5, or Message Digest 5, at 128 bits,"),
        (" No change was needed to the signing algorithm.", ""),
        ("Cracking the password would be wasted effort here, so a long password does not solve the problem. ", ""),
        (" A managed service account, where the system handles the password, is even better.", ""),
        (" It is like forging a ticket for one ride.", ""),
        (" Use long, random service account passwords. Keep tight", " Keep tight"),
        (" Restoring systems without fixing the way the attacker got in simply invites a repeat.", ""),
    ],
    "T29": [
        (" Consider how long recordings need to be kept, and check what the local privacy law allows.", ""),
        (" You will see them in front of shops and government buildings.", ""),
        (" Hinges should be on the inside.", ""),
        (" That way a door can open freely for safety and still be monitored for security.", ""),
    ],
    "T30": [
        (" A photograph of the seal, and a signature at each transfer, are simple and reliable methods.", ""),
        (" It also smooths out small faults and sags.", ""),
        ("\n\nHot aisle and cold aisle layouts arrange servers in rows so that cold air is drawn in on one side, and hot air is pushed out on the other. They make cooling more efficient.", ""),
        (" Earlier detection also means there will be more time for people to get out.", ""),
        (" Think about a guarded door with two different locks, each opened by a different person.", ""),
        (" You may still see it in old installations.", ""),
    ],
    "T31": [
        (" A person left out at this stage often turns into a problem later on.", ""),
        (" Security that ignores how people work tends to fail.", ""),
        (" A fresh pair of eyes will catch what the designer took for granted.", ""),
        ("\n\nIndependent testers are valuable at this point, because people tend not to see their own errors.", ""),
        (" Staff are not paid back on time.", ""),
        (" Nobody should go live on the basis that the team feels ready.", ""),
    ],
}


def load_part(topic_id):
    """Reads one topic part from the parts folder."""
    return json.loads((PARTS_FOLDER / f"{topic_id}.json").read_text(encoding="utf-8"))


def save_part(topic_id, part):
    """Writes one topic part back to the parts folder."""
    (PARTS_FOLDER / f"{topic_id}.json").write_text(
        json.dumps(part, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def apply_body_edits(topic_id, edits):
    """Applies each old-to-new text edit, and fails loudly if a target is not unique."""
    part = load_part(topic_id)
    for old_text, new_text in edits:
        matched = [segment for segment in part["studyNotes"] if old_text in segment["body"]]
        if len(matched) != 1:
            raise ValueError(f"{topic_id}: {old_text!r} matched {len(matched)} segments")
        matched[0]["body"] = matched[0]["body"].replace(old_text, new_text, 1)
    save_part(topic_id, part)


def replace_duplicate_option():
    """Replaces an option in T28 that repeated another wrong answer almost word for word."""
    part = load_part("T28")
    question = next(q for q in part["practiceQuestions"] if "password hash from a workstation" in q["prompt"])
    position = question["options"].index("Double the number of password characters for all users")
    question["options"][position] = "Force every user to change passwords each week"
    save_part("T28", part)


def balance_t30_answers():
    """Moves one T30 correct answer from position 2 to position 3, to even the spread."""
    part = load_part("T30")
    question = next(q for q in part["practiceQuestions"] if "humidity has been falling" in q["prompt"])
    question["options"][2], question["options"][3] = question["options"][3], question["options"][2]
    question["correctIndex"] = 3
    save_part("T30", part)


for topic, edit_list in BODY_EDITS.items():
    apply_body_edits(topic, edit_list)
replace_duplicate_option()
balance_t30_answers()
