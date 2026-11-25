# CISSP study notes: writing brief

The notes go inside a Flutter study app for one learner. They are a beginner who studies
1 hour a day and sits the exam on 2027-03-01. One topic is one hour of study, so each topic
needs real teaching, not a short summary. The exam follows the ISC2 CISSP outline effective
15 April 2024. Do not include material from any other outline.

## Language
- Very simple, clear English that a senior learner can understand and remember.
- Short sentences. One idea per sentence. Everyday examples (a house, a bank, a shop, a school).
- Explain every acronym and technical word in plain words the first time it appears in a topic.
- Facts must be correct. CISSP is precise. If a simple version loses a detail the exam tests, keep the detail and explain it.
- Teach the exam mindset where it fits: think like a manager and adviser, people's safety comes first,
  fix the cause rather than the symptom, get management support, follow policy.
- Write everything in your own words. Do not copy from the Official Study Guide, the CBK or any other book.
- Never use real, leaked or remembered exam questions. Write new questions in the same style.
- Do not mention AI, Claude, or who wrote the notes.

## Output
Write one JSON file, UTF-8, exact path given in your task. Valid JSON only. Exact shape:

{
  "number": 1,
  "name": "Security and Risk Management",
  "weightPercent": 16,
  "plainMeaning": "One or two sentences on what this domain is about, in plain words.",
  "topics": [
    {
      "id": "T01",
      "name": "Topic name",
      "outlineRef": "1.1",
      "simpleExplanation": "60 to 100 words. The whole idea, as you would tell a friend.",
      "studyNotes": [
        { "heading": "Short heading", "body": "Teaching text. Use \n\n between paragraphs and lines starting with '- ' for lists." }
      ],
      "keyTerms": [ { "term": "RTO", "meaning": "Recovery Time Objective: the longest a system may stay down." } ],
      "keyPoints": ["3 to 5 items, each one short sentence"],
      "memoryHook": "One memory hook or simple way to remember it.",
      "question": {
        "prompt": "Scenario-based, exam-style question.",
        "options": ["A", "B", "C", "D"],
        "correctIndex": 0,
        "explanation": "Short, simple reason. Say why the best answer wins and why the tempting wrong one loses."
      }
    }
  ],
  "examQuestions": [
    {
      "prompt": "...", "options": ["A","B","C","D"], "correctIndex": 2,
      "explanation": "...",
      "testsTopics": ["T01", "T03"]
    }
  ]
}

## Amounts
- `studyNotes`: 3 to 6 sections per topic, 350 to 600 words in total per topic. Cover everything the outline
  lists for that topic. Include a worked example for anything with numbers or steps. List items and exact orders the exam expects.
- `keyTerms`: 4 to 10 per topic.
- `keyPoints`: 3 to 5. `options`: exactly 4 per question. Options do not carry A/B/C/D letters.
- `examQuestions`: exactly 10 per domain, scenario-based, CISSP style (often "BEST", "FIRST", "MOST"),
  spread across all topics in the domain. `testsTopics` holds only IDs from this domain.

## Question quality
- Spread `correctIndex` evenly across 0, 1, 2 and 3.
- The correct option must not be the longest one by habit. Wrong options must be believable.
- Each question has one defensible best answer.
- The topic question and domain questions must test different scenarios.

## Finish
Run `python3 -c "import json;json.load(open('<path>'))"` to prove the file is valid JSON. Fix it if not.
Check the topic IDs are exactly those in your task. Reply in two lines: the file path and the counts of topics and questions.
Do not touch any other file in the project.
