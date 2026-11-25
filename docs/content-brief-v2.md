# CISSP lessons, version 2: writing brief

Read the existing notes file named in your task first. You are deepening it, not starting again.
The learner is a beginner and a senior learner, 1 hour a day, exam 2027-03-01, ISC2 outline effective 15 April 2024.

## Teaching method
Objective by objective, in order. Short segments, one idea each. Plain spoken language, as if a calm teacher
is talking to one person. The app reads the text aloud, so it must sound natural when heard.
- Open each segment by saying what we are about to look at. Close it by saying what to take away.
- Use everyday examples, then a real workplace example.
- Explain every acronym and technical word when it first appears in a topic.
- Short sentences. No tables. Lists only for items the exam expects in an exact order or set.
- Avoid symbols that sound wrong aloud. Write "times" and "divided by" in spoken text; keep a written formula only if you also say it in words.
- Teach the exam mindset: think like a manager and adviser, people's safety first, fix the cause, follow policy.
- This is a teaching method only. Do not name or imitate any real teacher, and do not copy any course, book or video. Your own words only.
- Never use real, leaked or remembered exam questions. Do not mention AI or who wrote this.
- Facts must be exact. After writing, reread every number, order, definition and answer key, and fix any error.

## What changes in each topic
Keep these exactly as they are unless a fact is wrong: id, name, outlineRef, simpleExplanation, keyTerms, keyPoints, memoryHook, question.
- `studyNotes`: replace with 5 or 6 segments, each `{ "heading", "body" }`. Each body is 300 to 400 words. Each topic totals 1,800 to 2,400 words.
  Use \n\n between paragraphs. Lines beginning "- " make a bullet list. Cover everything the outline lists for the topic, with a worked example for anything with numbers or steps.
- `practiceQuestions`: add exactly 10 new questions: `{ "prompt", "options": [4 items], "correctIndex", "explanation" }`.
  Scenario-based, exam style (BEST, FIRST, MOST), and different from the topic's `question` and from the domain's `examQuestions`.
  Spread correctIndex evenly across 0 to 3. The correct option must not usually be the longest. One defensible best answer each. Options carry no letters.

## What changes in the domain
- Keep number, name, weightPercent, plainMeaning and examQuestions.
- `reviewSession`: add 8 to 12 items, each `{ "heading", "body" }`, 100 to 180 words each. This is a spoken recap of the whole domain,
  like a teacher going back over the objectives before the exam: what is most tested, what people mix up, and how to choose the best answer.

## How to work
Write each topic to its own file in the parts folder named in your task, then merge them with a script kept in that same folder.
Use only that folder and the output path. Do not touch any other file. Other agents share this machine.
Before finishing, prove with a script that: the JSON is valid, every topic has 5 or 6 segments of 300 to 400 words and exactly 10 practiceQuestions with 4 options each,
and the reviewSession has 8 to 12 items. Reply in two lines: the file path and the counts.
