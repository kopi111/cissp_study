"""One-off edits: trims over-length segments and evens out option lengths.

Every edit must match exactly once, so a typo stops the run instead of being skipped.
"""
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent

SENTENCES_TO_REMOVE = {
    "T58": [
        "Trying to clean a system while the attack is still spreading is a waste of effort.",
        "Nor should they go back and argue about detection.",
    ],
    "T59": [
        "A related service is MDR, or managed detection and response, which focuses on finding and reacting to threats.",
        "Or think about a bomb disposal team that carries a suspicious package to a blast-proof chamber before examining it.",
        "Think about the difference between leaving your garden shed unlocked, and calling a stranger and inviting him to steal your lawnmower.",
    ],
    "T60": ["It is never acceptable as an accident or as an oversight."],
    "T61": [
        "The connection is checked straight afterwards.",
        "Sales staff are told beforehand.",
        "They confirm that the data going across will be encrypted.",
        "Think of drafts of a document. If you keep only one copy and overwrite it every day, you can never go back.",
        "Measures help a manager to understand the process. Examples are the percentage of changes that failed, the number of emergency changes, and the number of unauthorised changes found.",
    ],
    "T62": [
        "It should be far enough away that one flood or storm cannot affect both sites.",
        "So check how long it would really take.",
        "Spending more than the risk justifies is also a mistake.",
        "But it should still be possible for staff to travel there, or to work from it remotely.",
        "Many organisations now use the cloud in place of a traditional warm site.",
        "Think of a parking space. A numbered space with your name on it is reserved. A permit that lets you use any free space, when one is available, is not the same thing.",
        "Two servers in the same rack on the same power feed are not truly independent.",
    ],
    "T63": [
        "Until then, the emergency arrangements are still in effect.",
        "This is written down.",
        "Notice also that the disaster did not end when the hot site began working.",
        "Team members should know where to find the plan even when the company's systems are down, and should know who their backup is.",
    ],
    "T64": [
        "It also makes sure that people have read the plan at all.",
        "Care must be taken so that the two sets of work do not interfere with each other, such as sending the same payment twice.",
        "It is sometimes called a full cutover test.",
        "There is no sense in spending money on a test of a plan that still contains basic errors.",
        "Six minus four is two.",
        "Also notice that the test was useful even though it missed the target.",
        "That keeps people from being overwhelmed by a flood of competing messages.",
        "You should treat this as a compliance duty and not as an afterthought.",
    ],
    "T65": [
        "A useful way to separate them is by timing and by focus. Continuity planning tends to be about keeping critical functions going throughout an event. Disaster recovery tends to take over when the normal environment has been lost, and it works towards restoring it.",
        "Think about the things those people would know. Legal knows what must be reported. Human resources knows how to reach staff. Facilities knows about the building and the power.",
        "It does not work the other way round.",
        "Each thing has its own level of urgency.",
        "A similar trap is a very low RPO being claimed, but nothing in place to achieve it. Always check whether the backup schedule can really meet the stated figure.",
        "A word about terms. An exercise and a test are often used to mean nearly the same thing, but a test more often has a pass or fail result, and an exercise is often more about practice.",
        "A common approach is to review it at least once a year, and to review it again after any major change.",
        "Old copies should be withdrawn, because an out-of-date instruction can cause real harm during a crisis.",
    ],
    "T66": [
        "A door may also need to fail safe and fail secure at the same time, in different directions. Good design handles this properly.",
        "Paths and signs lead visitors to where you want them.",
        "A smart card contains a small chip, which makes it harder to copy than a simple magnetic card.",
        "Combination locks need the code changed when someone leaves.",
        "Printers and copiers should be placed in monitored spaces.",
        "This extends to executives and to staff who work alone at night. Lone workers may carry a device that sends an alert if they do not check in on time.",
        "In the panic of the moment, nobody has to think.",
        "Be careful of public charging points, shared computers in hotels, and free USB sticks, which are small plug-in storage devices that could carry harmful software.",
        "A hotel safe is better than an open desk, but it is not fully secure either.",
        "Organisations should also know where their people are, so that they can reach them in a crisis.",
        "Education goes further still, by building a deeper understanding.",
        "Reporting should be confidential, and it should be fair to the person concerned.",
        "A public post saying that you are in another country helps someone pretend to be you.",
        "Controls such as least privilege and separation of duties limit the possible harm.",
    ],
}

TEXT_REPLACEMENTS = {
    "T53": [
        ("Step two, she captures memory, using a trusted tool.",
         "Registers and cache change too fast to capture separately in most cases, so step two, she captures memory, using a trusted tool."),
    ],
    "T55": [
        ("\"The change advisory board's meeting notes\"", "\"The minutes from the change advisory board's last meeting\""),
        ("\"After the first vulnerability scan of the live network\"", "\"After the first vulnerability scan of the live production network\""),
        ("\"Regression testing\"", "\"Regression testing after an upgrade\""),
        ("\"Shut down the whole network segment immediately\"", "\"Shut down the whole network segment immediately as a precaution\""),
    ],
    "T58": [
        ("\"Report the matter to the industry regulator\"", "\"Report the matter to the industry regulator without any delay\""),
        ("\"Find out which staff member opened the attachment\"", "\"Find out exactly which staff member opened the attachment\""),
        ("\"Run a clean-up tool and then restart it\"", "\"Run a clean-up tool and then restart it to confirm the result\""),
        ("\"The restore was carried out at the wrong time of day\"", "\"The restore was carried out at the wrong time of day by mistake\""),
    ],
    "T59": [
        ("\"A deny list of known bad programs\"", "\"A deny list of all known bad programs and files\""),
        ("\"Hand over all accountability for security to the provider\"", "\"Hand over all accountability for the company's security to the provider\""),
        ("\"Replace all other security tools with this single product\"", "\"Replace all of the other security tools with this single new product\""),
    ],
    "T60": [
        ("\"Notice to all employees of the exact test time\"", "\"Advance notice to all employees of the exact test date and time\""),
        ("\"Neither, until the next quarterly maintenance period\"", "\"Neither of them, until the next quarterly maintenance period has come\""),
    ],
    "T63": [
        ("\"Copy the latest backups onto portable drives\"", "\"Copy the latest backups onto portable drives and carry them out\""),
        ("\"The function requested by the most senior manager on site\"", "\"The function requested by the most senior manager present on the site\""),
        ("\"The plan may be read by too many members of staff\"", "\"The plan may be read and copied by too many members of staff at once\""),
    ],
    "T65": [(", no matter how hopeful you are", "")],
}


def remove_sentence(text, sentence):
    """Removes one sentence and the single space that joined it to its neighbour."""
    for candidate in (" " + sentence, sentence + " ", "\\n\\n" + sentence):
        if text.count(candidate) == 1:
            return text.replace(candidate, "")
    raise ValueError(f"Could not place sentence exactly once: {sentence}")


def replace_once(text, old, new):
    """Replaces text that must appear exactly once."""
    if text.count(old) != 1:
        raise ValueError(f"Expected one match for: {old}")
    return text.replace(old, new)


def edit_topic(topic_id):
    """Applies every planned edit to one part file."""
    path = PARTS_FOLDER / f"{topic_id}.json"
    text = path.read_text(encoding="utf-8")
    for sentence in SENTENCES_TO_REMOVE.get(topic_id, []):
        text = remove_sentence(text, sentence)
    for old, new in TEXT_REPLACEMENTS.get(topic_id, []):
        text = replace_once(text, old, new)
    path.write_text(text, encoding="utf-8")


def main():
    """Edits every topic that has planned changes."""
    already_done = {"T53", "T55", "T58"}
    for topic_id in sorted((set(SENTENCES_TO_REMOVE) | set(TEXT_REPLACEMENTS)) - already_done):
        edit_topic(topic_id)


if __name__ == "__main__":
    main()
