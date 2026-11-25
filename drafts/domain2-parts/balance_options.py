"""One-off editing pass: rewords options so the correct answer is not given away by being short."""
import json
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent

# New wording for the correct option, keyed by topic and then by question position (0 to 9).
CORRECT_OPTION_WORDING = {
    "T13": {
        0: "Refuse for now, because he has no need to know what is in a report for that project",
        1: "Map the two schemes to each other in an approved policy, and tell staff how they line up",
        2: "Have the owner review the combined collection and assign it a higher class than its parts",
        4: "Ask the owner to review the class, and to lower it if the harm has really fallen",
        5: "Have the owners reclassify items against clear criteria, and then retrain the staff on them",
        6: "It lets the company match its protection spending to the value of each item that it holds",
    },
    "T14": {
        0: "Disagree, because when every item carries a mark, a missing mark stands out as a mistake",
        1: "Add a machine-readable label to the metadata of each file that can be read by the software",
        2: "Store the keys separately from the disks, under the control of a different authorized person",
        3: "Give the backup disks the same protection that the original database already has",
        4: "A signed chain of custody record at every handover point",
        5: "A plain outer wrapping with no class shown, and the class marked on an inner wrapping",
        6: "Hold each print job on the system until the person who sent it badges in at the printer",
        7: "Publish written handling rules for each class, and then train the staff in all departments",
        8: "Store them in a controlled environment, and test-read a sample of the tapes from time to time",
        9: "Use the approved encrypted transfer service, and require the auditor to sign in to collect it",
    },
    "T15": {
        0: "The data owner did not approve the access before the administrator granted it",
        1: "Remove the old rights at each job change, and review everyone's access on a regular schedule",
        2: "The finance director, because owners cannot delegate accountability for their data",
        3: "Intangible assets, such as the company's data, its software licenses and its patents",
        4: "Investigate each one to learn what the device is, what it does and who is responsible for it",
        5: "Link the human resources leaving process to equipment return and to access removal",
        6: "Find out who uses the server in the business, and have management name an owner for it",
        7: "Track all software and its licenses as assets in the inventory, and keep the count current",
        8: "Make updating the record a required step of the change management process for every system",
        9: "Grant only the rights that have been approved in advance for the person's defined role",
    },
    "T16": {
        1: "The department acts as a custodian, because a processor is always a separate party",
        2: "For that use it has acted as a controller, and it has to answer for that decision",
        3: "The shop, because the controller must see that a data subject's rights are met",
        4: "Tell the insurer without undue delay, so that the insurer can meet its own duties",
        5: "Remove the questions about salary and employer from the form, and stop collecting both",
        6: "Check whether there is a lawful basis for using the numbers for this new purpose",
        7: "Restrict the backups to locations in that country, and confirm this in the contract",
        9: "Testing a full restore from those backups on a regular, recorded schedule",
    },
    "T17": {
        0: "Suspend deletion of the relevant email by placing it under a legal hold from the lawyers",
        1: "Adopt a retention schedule based on law, contracts and real business need for each record type",
        2: "Clear the drives with an approved overwriting software tool",
        3: "Purge each drive using its own secure-erase command, then verify that the data has gone",
        4: "Do not use the degausser at all, and physically shred the discs in a suitable machine",
        5: "It may not be enough, because data written before encryption began may remain unencrypted",
        6: "Destroy that remaining copy of the key as well, and record that it has been destroyed",
        7: "Plan and budget for replacing the switches well before the end of support date arrives",
        8: "Sanitize the internal drive using an approved method, and record that it was done",
        9: "Physically destroy them and keep a signed certificate",
    },
    "T18": {
        0: "Data in use, which calls for a privacy filter and an automatic lock on the reception screen",
        2: "Keep it, because a control that the law requires does apply and cannot be scoped out",
        3: "Document the reason for each change, and obtain management approval for each one",
        4: "Identify which laws and contracts bind the company in each of its new markets",
        5: "A Cloud Access Security Broker that works inline on each upload",
        6: "Disagree, because the data is only pseudonymized and can still be linked back to patients",
        8: "Endpoint Data Loss Prevention running on staff computers",
        9: "Tokenization, with real numbers held in a secure vault",
    },
}

# Wrong options that are reworded as well, keyed by topic and then by their exact current text.
WRONG_OPTION_WORDING = {
    "T15": {
        "Send a stronger letter to former staff reminding them that laptops belong to the company":
            "Send a stronger letter reminding former staff that laptops belong to the company",
    },
    "T16": {
        "Reviewing who has access to the backup system at the end of every three-month period":
            "Reviewing who has access to the backup system every three months",
    },
    "T18": {
        "Masking the card number on cashiers' screens": "Masking the card number on all of the cashiers' screens",
        "Digital Rights Management on exported reports": "Digital Rights Management on all of the exported reports",
        "Stronger passwords for all order system users": "Stronger passwords for all of the order system's users",
    },
}

# Corrections found on rereading the study notes, as (topic, exact old text, new text).
STUDY_NOTE_CORRECTIONS = [
    ("T13", "It then takes the highest of the three results for the system.",
     "The overall rating for the system then follows the highest of the three results."),
    ("T14", "so the page does not appear until its owner is standing there.",
     "so the page does not appear until the sender is standing there."),
    ("T17", "Automatic deletion must be suspended for the relevant data, even though the date has been reached.",
     "Automatic deletion must be suspended for the relevant data, and the invoice stays even when March 2027 arrives."),
    ("T17", "which has both magnetic platters and a flash chip, keeps whatever is on its chip.",
     "which has both magnetic platters and a memory chip, keeps whatever is on its chip."),
]


def reword_options(part):
    """Applies the new wording to one topic's practice questions."""
    correct_wording = CORRECT_OPTION_WORDING.get(part["id"], {})
    wrong_wording = WRONG_OPTION_WORDING.get(part["id"], {})
    for position, question in enumerate(part["practiceQuestions"]):
        question["options"] = [wrong_wording.get(option, option) for option in question["options"]]
        if position in correct_wording:
            question["options"][question["correctIndex"]] = correct_wording[position]


def correct_study_notes(part):
    """Applies every study note correction that belongs to this topic, and insists each one lands."""
    for topic_id, old_text, new_text in STUDY_NOTE_CORRECTIONS:
        if topic_id != part["id"]:
            continue
        matching = [segment for segment in part["studyNotes"] if old_text in segment["body"]]
        if len(matching) != 1:
            raise ValueError(f"{topic_id}: expected one match for: {old_text}")
        matching[0]["body"] = matching[0]["body"].replace(old_text, new_text)


def main():
    """Rewrites each topic part file in place."""
    for topic_id in CORRECT_OPTION_WORDING:
        path = PARTS_FOLDER / f"{topic_id}.json"
        part = json.loads(path.read_text(encoding="utf-8"))
        reword_options(part)
        correct_study_notes(part)
        path.write_text(json.dumps(part, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
