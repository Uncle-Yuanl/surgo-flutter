"""Enlarge small text across every feedback / review page.

User 2026-09-24 item 0: apply the same bump used on the writing review pages to
all the other correction-result pages. Only genuinely small sizes move; section
titles and big band scores keep their size so hierarchy is preserved.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGETS = [
    "lib/features/ielts_listening/feedback_audio.dart",
    "lib/features/ielts_listening/feedback_body.dart",
    "lib/features/ielts_listening/feedback_questions.dart",
    "lib/features/ielts_listening/listening_feedback.dart",
    "lib/features/ielts_reading/reading_feedback.dart",
    "lib/features/ielts_reading/review_passage.dart",
    "lib/features/ielts_reading/review_questions.dart",
    "lib/features/ielts_reading/review_summary.dart",
    "lib/features/speaking_review/speaking_review_page.dart",
    "lib/features/tf_listening_daily/review.dart",
    "lib/features/tf_listening_mock/feedback.dart",
    "lib/features/tf_reading_mock/review.dart",
    "lib/features/tf_speaking_daily/review.dart",
    "lib/features/tf_speaking_mock/review.dart",
    "lib/features/tf_writing/feedback.dart",
    "lib/features/toefl_life/toefl_life_feedback.dart",
    "lib/features/toefl_words/toefl_words_feedback.dart",
]
BUMP = {
    "10": "12",
    "10.5": "12.5",
    "11": "13",
    "11.5": "13",
    "12": "13.5",
    "12.5": "13.5",
}

changed = []
for rel in TARGETS:
    path = ROOT / rel
    if not path.is_file():
        print(f"missing: {rel}")
        continue
    text = path.read_text()
    original = text

    def repl(match):
        value = match.group(1)
        return f"fontSize: {BUMP[value]}" if value in BUMP else match.group(0)

    text = re.sub(r"fontSize: (\d+(?:\.\d+)?)", repl, text)
    # SurgoText.css(n) wraps declared CSS sizes; bump those too.
    def repl_css(match):
        value = match.group(1)
        return f"SurgoText.css({BUMP[value]})" if value in BUMP else match.group(0)

    text = re.sub(r"SurgoText\.css\((\d+(?:\.\d+)?)\)", repl_css, text)
    if text != original:
        path.write_text(text)
        changed.append(rel)

print(f"{len(changed)} files bumped")
for rel in changed:
    print("  " + rel)
if not changed:
    sys.exit(1)
