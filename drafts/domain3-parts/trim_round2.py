"""Second pass: removes named sentences from topic parts to meet the word limits."""
import json
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent

REMOVALS = {
    "T22": [
        "These two features work well together. ",
    ],
    "T26": [
        " Real Diffie-Hellman does this with very large numbers.",
        " A question that says we hashed the file to keep it secret has made a mistake.",
        "\n\nThis is why that private key is so valuable. It is usually kept in a Hardware Security Module, a device built to protect keys.",
        "Both of those are also compared with symmetric keys. ",
    ],
    "T27": [
        " If an intermediate is compromised, only that branch has to be replaced.",
        "\n\nA certificate has a signature, and that signature is what stops anyone from altering the contents. Change one letter, and the signature check fails.",
        " Think about a stolen passport. It has not expired, but it must not be accepted any more.",
        " Do not wait for the certificate to expire.",
        " A client that has an old list could accept a cancelled certificate.",
        " The client does not need to contact the authority.",
        " NIST, the United States National Institute of Standards and Technology, publishes guidance about this.",
        "\n\nBacking up a private key used only for signing is usually a poor idea. Recovery matters for encryption keys, because the data would otherwise be lost.",
        " Each officer signs a log, and the event is watched.",
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
