"""Replaces practice questions that were too close to a topic or domain exam question."""
import json
from pathlib import Path

PARTS_FOLDER = Path(__file__).resolve().parent

REPLACEMENTS = {
    "T55": ("Administrators keep fixing the same weak setting", {
        "prompt": "A department creates cloud servers using its own credit card. The servers appear in no record and nobody patches them. What is the BEST long-term response?",
        "options": [
            "Scan the public internet once a year for the company's servers",
            "Ban every use of cloud services across the whole company",
            "Bring cloud provisioning under the approved, recorded process",
            "Ask the department to keep its own spreadsheet of the servers"],
        "correctIndex": 2,
        "explanation": "An approved process means new servers are hardened, recorded and patched. A ban is tempting, but it ignores the business need and tends to push the activity further out of sight."}),
    "T57": ("A courier loses a sealed bag", {
        "prompt": "Staff keep plugging unknown USB sticks into office computers, and one of them carried malware. Which control would BEST reduce this risk?",
        "options": [
            "Send a monthly email asking staff to take care with USB sticks",
            "Increase the required length of staff account passwords",
            "Move the office computers to a different floor of the building",
            "Technically block USB ports except for approved, encrypted drives"],
        "correctIndex": 3,
        "explanation": "A technical control on the ports works every time, whatever staff remember. A monthly email is tempting, but a reminder alone does not stop someone from plugging in a stick."}),
    "T58": ("An analyst confirms that an employee's laptop", {
        "prompt": "An attack is still spreading when a director demands that the incident team stop and write a full report before doing anything else. What should the incident manager do?",
        "options": [
            "Stop all containment work and write the full report as requested",
            "Ignore the director completely until the incident has been closed",
            "Ask the press office to write the report on the team's behalf",
            "Give a brief update now and carry on containing the attack"],
        "correctIndex": 3,
        "explanation": "Mitigation limits the damage, and reporting continues alongside it, so a short update meets both needs. Writing the full report first is tempting because a senior person asked, but the attack would keep spreading."}),
    "T61": ("A developer at a bank has been writing code", {
        "prompt": "An engineer raises a change request, approves it personally and then carries it out. What is the MAIN risk?",
        "options": [
            "The change may take longer to complete than was planned",
            "A harmful or careless change could go live with no independent check",
            "The engineer will have too much work to do",
            "The ticket numbering may become harder to read"],
        "correctIndex": 1,
        "explanation": "When one person controls every stage, there is no independent check on what goes live. Extra workload is tempting as a concern, but it is not the security problem."}),
    "T64": ("A company's main site must keep operating normally", {
        "prompt": "During a test, staff bring up systems at the recovery site and process a copy of the day's orders there, while the main site carries on as normal. Which test is this?",
        "options": [
            "Walkthrough",
            "Full interruption test",
            "Tabletop exercise",
            "Parallel test"],
        "correctIndex": 3,
        "explanation": "The recovery site really runs the work while the main site continues, which is a parallel test. Full interruption is tempting because real work runs at the recovery site, but in that test the main site is shut down."}),
}


def replace_question(topic_id, prompt_start, new_question):
    """Swaps the one question whose prompt starts with the given words."""
    path = PARTS_FOLDER / f"{topic_id}.json"
    part = json.loads(path.read_text(encoding="utf-8"))
    matches = [i for i, q in enumerate(part["practiceQuestions"]) if q["prompt"].startswith(prompt_start)]
    if len(matches) != 1:
        raise ValueError(f"{topic_id}: expected one match for {prompt_start}")
    part["practiceQuestions"][matches[0]] = new_question
    path.write_text(json.dumps(part, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


for topic_id, (prompt_start, new_question) in REPLACEMENTS.items():
    replace_question(topic_id, prompt_start, new_question)
