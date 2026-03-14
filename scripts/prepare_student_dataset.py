#!/usr/bin/env python3
"""
Prepare the student dataset from a Meta Content Library CSV export.

Three-phase pipeline:
  score    - Score all posts for AI slop likelihood (heuristic)
  select   - Sample ~420 posts (350 AI slop + 70 non-slop)
  download - Download multimedia content for selected posts

Usage:
  python scripts/prepare_student_dataset.py score
  python scripts/prepare_student_dataset.py select
  python scripts/prepare_student_dataset.py download --cookie "cookie_string"
  python scripts/prepare_student_dataset.py all --cookie "cookie_string"
"""

import argparse
import csv
import json
import os
import re
import sys
import time
import random
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

try:
    import requests
except ImportError:
    requests = None

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent
INPUT_CSV = PROJECT_ROOT / "data" / "raw" / "download_1773487735.csv"
FULL_SCORED_CSV = PROJECT_ROOT / "data" / "full-scored.csv"
OUTPUT_DIR = PROJECT_ROOT / "data" / "student-dataset"
METADATA_CSV = OUTPUT_DIR / "metadata.csv"
MEDIA_DIR = OUTPUT_DIR / "media"
DOWNLOAD_LOG = OUTPUT_DIR / "download_log.json"

TARGET_SLOP = 350
TARGET_NONSLOP = 70
RANDOM_SEED = 42

# ---------------------------------------------------------------------------
# Regex patterns for AI slop detection
# ---------------------------------------------------------------------------

RE_HASHTAG_FARM = re.compile(
    r"#(?:fblifestyle|viralpost|reelschallenge|postviral|fbreels|facebookreels"
    r"|virale|reelsitalia|postvirale)",
    re.IGNORECASE,
)

RE_BIRTHDAY_BAIT = re.compile(
    r"(?:oggi\s+(?:è|e)\s+il\s+mio\s+compleanno"
    r"|compi\s+\d+\s+anni"
    r"|buon\s+compleanno\s+a\s+me"
    r"|nessuno\s+(?:mi\s+)?(?:ha\s+)?(?:fatto|augurato)"
    r"|auguri\s+a\s+me\b)",
    re.IGNORECASE,
)

RE_ENGAGEMENT_PROMPT = re.compile(
    r"(?:scrivi\s+amen"
    r"|metti\s+(?:un\s+)?(?:like|mi piace)"
    r"|un\s+aggettivo\s+(?:su|per)\s+quest"
    r"|qualifica\s+(?:il\s+mio|questo)"
    r"|commenta\s+con"
    r"|chi\s+(?:è|e)\s+d'accordo"
    r"|condividi\s+se"
    r"|ignorare\s+se"
    r"|tipo\s+e\s+condividi"
    r"|scrivi\s+s[iì]\s+nei\s+commenti)",
    re.IGNORECASE,
)

RE_CLICKBAIT_NEWS = re.compile(
    r"(?:allerta\s+(?:meteo|rossa|arancione)"
    r"|terremoto\s+(?:di|a|in)\s"
    r"|ultima\s+ora\s*[:\!]"
    r"|breaking\s*[:\!]"
    r"|notizia\s+(?:shock|bomba)"
    r"|non\s+crederete\s+(?:a\s+)?(?:cosa|quello)"
    r"|ecco\s+(?:cosa|quello)\s+(?:che\s+)?(?:è\s+)?successo)",
    re.IGNORECASE,
)

RE_RELIGIOUS_BAIT = re.compile(
    r"(?:\bamen\b"
    r"|scrivi\s+ges[uù]"
    r"|prega\s+con\s+(?:me|noi)"
    r"|benedizione\s+per\s+(?:te|chi)"
    r"|dio\s+(?:ti\s+)?benedica"
    r"|preghiera\s+(?:per|della))",
    re.IGNORECASE,
)

RE_EMOTIONAL_AI = re.compile(
    r"(?:una\s+storia\s+che\s+(?:tocca|commuove)"
    r"|il\s+cuore\s+(?:si\s+)?(?:spezza|scioglie)"
    r"|non\s+(?:riesco|riesce)\s+a\s+trattenere\s+le\s+lacrime"
    r"|vi\s+(?:prego|supplico)"
    r"|ha\s+commosso\s+(?:il\s+)?(?:mondo|tutti)"
    r"|guerrier[ao]\s+(?:che\s+non\s+si\s+arrende|del(?:la)?\s+vita))",
    re.IGNORECASE,
)

RE_TRUNCATED = re.compile(r"\.\.\s*Altro\s*$", re.IGNORECASE)

RE_HEALTH_SCARE = re.compile(
    r"(?:sintom[io]\s+(?:del|di)\s+(?:cancro|tumore|diabete|ictus)"
    r"|(?:cancro|tumore)\s+(?:al|del|della)"
    r"|(?:medici|dottori)\s+(?:non\s+)?(?:vogliono|dicono)"
    r"|rimedio\s+naturale\s+(?:che|per)"
    r"|le\s+vene\s+(?:varicose|gonfie))",
    re.IGNORECASE,
)

RE_HOROSCOPE = re.compile(
    r"(?:oroscopo\s+(?:di\s+)?(?:oggi|domani|settimanale)"
    r"|segn[io]\s+zodiacal[ei]"
    r"|(?:ariete|toro|gemelli|cancro|leone|vergine"
    r"|bilancia|scorpione|sagittario|capricorno|acquario|pesci)"
    r"\s*[,:\-]\s*(?:oggi|questa\s+settimana))",
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# CSV helpers
# ---------------------------------------------------------------------------

def read_csv(path):
    """Read CSV handling the BOM in the first column."""
    rows = []
    with open(path, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows


def write_csv(path, rows, fieldnames):
    """Write rows to CSV."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    print(f"  Wrote {len(rows)} rows to {path}")


def safe_int(val, default=0):
    try:
        return int(val)
    except (ValueError, TypeError):
        return default


def safe_float(val, default=0.0):
    try:
        return float(val)
    except (ValueError, TypeError):
        return default


# ---------------------------------------------------------------------------
# Phase 1: Score
# ---------------------------------------------------------------------------

def assign_category(row):
    """Assign a content category based on text patterns."""
    text = row.get("text", "")
    if RE_BIRTHDAY_BAIT.search(text):
        return "birthday_bait"
    if RE_RELIGIOUS_BAIT.search(text):
        return "religious_bait"
    if RE_CLICKBAIT_NEWS.search(text):
        return "clickbait_news"
    if RE_HEALTH_SCARE.search(text):
        return "health_scare"
    if RE_HOROSCOPE.search(text):
        return "horoscope"
    if RE_ENGAGEMENT_PROMPT.search(text):
        return "engagement_prompt"
    if RE_EMOTIONAL_AI.search(text):
        return "emotional_story"
    if RE_HASHTAG_FARM.search(text):
        return "hashtag_farm"
    if RE_TRUNCATED.search(text):
        return "truncated_clickbait"
    return "other"


def score_posts(rows):
    """Score each post for AI slop likelihood. Returns rows with added fields."""
    print("Phase 1: Scoring posts...")

    # --- Pass 1: build coordination index (text[:100] -> set of page names) ---
    text_to_pages = defaultdict(set)
    for row in rows:
        text_key = row.get("text", "")[:100].strip().lower()
        if len(text_key) > 10:  # skip very short texts
            page = row.get("post_owner.name", "")
            text_to_pages[text_key].add(page)

    # --- Pass 2: build per-page median reactions ---
    page_reactions = defaultdict(list)
    for row in rows:
        page = row.get("post_owner.name", "")
        rc = safe_int(row.get("statistics.reaction_count"))
        page_reactions[page].append(rc)

    page_medians = {}
    for page, vals in page_reactions.items():
        sorted_vals = sorted(vals)
        mid = len(sorted_vals) // 2
        page_medians[page] = sorted_vals[mid] if sorted_vals else 0

    # --- Pass 3: score each post ---
    for row in rows:
        score = 0
        text = row.get("text", "")
        text_key = text[:100].strip().lower()

        # Coordination signal
        if len(text_key) > 10 and len(text_to_pages.get(text_key, set())) >= 3:
            score += 3

        # Hashtag farming
        if RE_HASHTAG_FARM.search(text):
            score += 2

        # Birthday bait
        if RE_BIRTHDAY_BAIT.search(text):
            score += 2

        # Engagement prompts
        if RE_ENGAGEMENT_PROMPT.search(text):
            score += 2

        # Clickbait news
        if RE_CLICKBAIT_NEWS.search(text):
            score += 2

        # Religious bait
        if RE_RELIGIOUS_BAIT.search(text):
            score += 2

        # Health scare
        if RE_HEALTH_SCARE.search(text):
            score += 2

        # Emotional AI pattern
        if RE_EMOTIONAL_AI.search(text):
            score += 1

        # Truncated clickbait
        if RE_TRUNCATED.search(text):
            score += 1

        # Content type = photos
        if row.get("content_type") == "photos":
            score += 1

        # High engagement relative to page median
        page = row.get("post_owner.name", "")
        rc = safe_int(row.get("statistics.reaction_count"))
        median = page_medians.get(page, 0)
        if median > 0 and rc > 3 * median:
            score += 1

        row["slop_score"] = score
        row["slop_category"] = assign_category(row)

    # --- Summary ---
    score_dist = Counter(row["slop_score"] for row in rows)
    print(f"  Score distribution:")
    for s in sorted(score_dist.keys()):
        print(f"    score={s}: {score_dist[s]:,} posts")

    high = sum(1 for r in rows if r["slop_score"] >= 5)
    print(f"  Posts with score >= 5: {high:,}")

    return rows


def cmd_score(args):
    """Score all posts and write full-scored.csv."""
    rows = read_csv(INPUT_CSV)
    print(f"  Loaded {len(rows):,} posts from {INPUT_CSV.name}")

    rows = score_posts(rows)

    fieldnames = list(rows[0].keys())
    write_csv(FULL_SCORED_CSV, rows, fieldnames)
    print("Phase 1 complete.")
    return rows


# ---------------------------------------------------------------------------
# Phase 2: Select
# ---------------------------------------------------------------------------

def select_dataset(rows, target_slop=TARGET_SLOP, target_nonslop=TARGET_NONSLOP):
    """Stratified sample of posts for the student dataset."""
    print(f"\nPhase 2: Selecting ~{target_slop + target_nonslop} posts...")
    rng = random.Random(RANDOM_SEED)

    # --- AI slop candidates: score >= 5, deduplicate by text[:100] ---
    slop_pool = [r for r in rows if r["slop_score"] >= 5]
    print(f"  AI slop pool (score >= 5): {len(slop_pool):,}")

    # Deduplicate: keep highest-engagement version of each text template
    deduped = {}
    for row in slop_pool:
        text_key = row.get("text", "")[:100].strip().lower()
        rc = safe_int(row.get("statistics.reaction_count"))
        if text_key not in deduped or rc > safe_int(deduped[text_key].get("statistics.reaction_count")):
            deduped[text_key] = row
    slop_unique = list(deduped.values())
    print(f"  After deduplication: {len(slop_unique):,} unique templates")

    # Group by category
    by_cat = defaultdict(list)
    for row in slop_unique:
        by_cat[row["slop_category"]].append(row)

    # Target distribution per category (flexible — fills up to target_slop)
    cat_targets = {
        "birthday_bait": 60,
        "emotional_story": 50,
        "clickbait_news": 50,
        "religious_bait": 40,
        "engagement_prompt": 30,
        "health_scare": 25,
        "horoscope": 15,
        "hashtag_farm": 30,
        "truncated_clickbait": 20,
        "other": 30,
    }

    selected_slop = []
    for cat, target in cat_targets.items():
        available = by_cat.get(cat, [])
        n = min(target, len(available))
        if available:
            sampled = rng.sample(available, n)
            selected_slop.extend(sampled)
            print(f"    {cat}: sampled {n} / {len(available)} available")

    # If under target, fill from remaining high-score posts
    if len(selected_slop) < target_slop:
        selected_ids = {r["id"] for r in selected_slop}
        remaining = [r for r in slop_unique if r["id"] not in selected_ids]
        remaining.sort(key=lambda r: safe_int(r.get("statistics.reaction_count")), reverse=True)
        fill = remaining[: target_slop - len(selected_slop)]
        selected_slop.extend(fill)
        print(f"    fill: added {len(fill)} more to reach target")

    # Trim if over target
    if len(selected_slop) > target_slop:
        rng.shuffle(selected_slop)
        selected_slop = selected_slop[:target_slop]

    for r in selected_slop:
        r["is_slop"] = "True"

    print(f"  Selected AI slop: {len(selected_slop)}")

    # --- Non-AI-slop: score <= 1, photos, diverse pages ---
    nonslop_pool = [
        r for r in rows
        if r["slop_score"] <= 1
        and r.get("content_type") in ("photos", "videos")
    ]
    # Deduplicate
    nonslop_deduped = {}
    for row in nonslop_pool:
        text_key = row.get("text", "")[:100].strip().lower()
        if text_key not in nonslop_deduped:
            nonslop_deduped[text_key] = row
    nonslop_unique = list(nonslop_deduped.values())

    # Sample from diverse pages
    nonslop_by_page = defaultdict(list)
    for row in nonslop_unique:
        nonslop_by_page[row.get("post_owner.name", "")].append(row)

    selected_nonslop = []
    pages = list(nonslop_by_page.keys())
    rng.shuffle(pages)
    per_page = max(1, target_nonslop // min(len(pages), target_nonslop))
    for page in pages:
        if len(selected_nonslop) >= target_nonslop:
            break
        available = nonslop_by_page[page]
        n = min(per_page, len(available), target_nonslop - len(selected_nonslop))
        selected_nonslop.extend(rng.sample(available, n))

    for r in selected_nonslop:
        r["is_slop"] = "False"
        r["slop_category"] = "non_slop"

    print(f"  Selected non-slop: {len(selected_nonslop)}")

    # --- Combine and shuffle ---
    selected = selected_slop + selected_nonslop
    rng.shuffle(selected)
    print(f"  Total selected: {len(selected)}")

    return selected


def cmd_select(args):
    """Select posts and write metadata.csv."""
    # Try to load scored CSV first; fall back to scoring from raw
    if FULL_SCORED_CSV.exists():
        rows = read_csv(FULL_SCORED_CSV)
        # Restore int types for slop_score
        for r in rows:
            r["slop_score"] = safe_int(r.get("slop_score"))
        print(f"  Loaded {len(rows):,} scored posts from {FULL_SCORED_CSV.name}")
    else:
        print("  No scored CSV found. Running scoring first...")
        rows = cmd_score(args)
        for r in rows:
            r["slop_score"] = safe_int(r.get("slop_score"))

    selected = select_dataset(rows)

    # Count multimedia items
    for row in selected:
        try:
            mm = json.loads(row.get("multimedia", "[]"))
            row["multimedia_count"] = len(mm)
        except (json.JSONDecodeError, TypeError):
            row["multimedia_count"] = 0

    # Write metadata CSV
    fieldnames = [
        "id", "post_owner.name", "text", "content_type", "creation_time",
        "statistics.reaction_count", "statistics.like_count",
        "statistics.love_count", "statistics.haha_count",
        "statistics.wow_count", "statistics.sad_count",
        "statistics.angry_count", "statistics.care_count",
        "statistics.comment_count", "statistics.share_count",
        "statistics.views",
        "multimedia_count", "slop_score", "slop_category", "is_slop",
    ]
    write_csv(METADATA_CSV, selected, fieldnames)
    print("Phase 2 complete.")
    return selected


# ---------------------------------------------------------------------------
# Phase 3: Download
# ---------------------------------------------------------------------------

def download_one(url, filepath, cookie_header, retries=3):
    """Download a single file with retry logic."""
    headers = {
        "Cookie": cookie_header,
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
    }
    for attempt in range(retries):
        try:
            resp = requests.get(url, headers=headers, timeout=60, stream=True)
            if resp.status_code == 200:
                content_type = resp.headers.get("Content-Type", "")
                # Infer extension
                if "video" in content_type:
                    ext = ".mp4"
                elif "png" in content_type:
                    ext = ".png"
                elif "gif" in content_type:
                    ext = ".gif"
                else:
                    ext = ".jpg"
                # Update filepath with correct extension
                final_path = filepath.with_suffix(ext)
                with open(final_path, "wb") as f:
                    for chunk in resp.iter_content(8192):
                        f.write(chunk)
                size = final_path.stat().st_size
                return {"status": "ok", "path": str(final_path), "size": size}
            elif resp.status_code == 401:
                return {"status": "auth_error", "code": 401}
            elif resp.status_code in (429, 500, 502, 503):
                time.sleep(2 ** attempt)
                continue
            else:
                return {"status": "http_error", "code": resp.status_code}
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
            else:
                return {"status": "error", "message": str(e)}
    return {"status": "failed", "retries": retries}


def cmd_download(args):
    """Download multimedia for selected posts."""
    if not requests:
        print("ERROR: 'requests' package required. Install with: pip install requests")
        sys.exit(1)

    cookie = args.cookie
    if not cookie:
        print("ERROR: --cookie is required for download.")
        print("Export cookies from your MCL browser session.")
        sys.exit(1)

    # Load selected posts
    if not METADATA_CSV.exists():
        print(f"  {METADATA_CSV} not found. Running select first...")
        cmd_select(args)

    selected = read_csv(METADATA_CSV)
    print(f"\nPhase 3: Downloading media for {len(selected)} posts...")

    # We need the multimedia URLs from the full scored CSV or raw CSV
    # Load the full data to get multimedia column
    if FULL_SCORED_CSV.exists():
        source = FULL_SCORED_CSV
    else:
        source = INPUT_CSV
    all_rows = read_csv(source)
    multimedia_lookup = {r["id"]: r.get("multimedia", "[]") for r in all_rows}

    MEDIA_DIR.mkdir(parents=True, exist_ok=True)

    # Build download queue
    queue = []
    for row in selected:
        post_id = row["id"]
        mm_json = multimedia_lookup.get(post_id, "[]")
        try:
            items = json.loads(mm_json)
        except (json.JSONDecodeError, TypeError):
            items = []
        for idx, item in enumerate(items):
            url = item.get("url", "")
            media_type = item.get("type", "photo")
            default_ext = ".mp4" if media_type == "video" else ".jpg"
            filepath = MEDIA_DIR / f"{post_id}_{idx}{default_ext}"
            # Skip if any version already exists
            existing = list(MEDIA_DIR.glob(f"{post_id}_{idx}.*"))
            if existing:
                continue
            queue.append((url, filepath, post_id, idx))

    print(f"  Files to download: {len(queue)} (skipping already downloaded)")

    if not queue:
        print("  Nothing to download.")
        return

    # Test first URL
    print("  Testing authentication with first URL...")
    test_result = download_one(queue[0][0], queue[0][1], cookie)
    if test_result["status"] == "auth_error":
        print("  ERROR: Authentication failed (HTTP 401).")
        print("  Your cookies may have expired. Export fresh cookies from MCL.")
        sys.exit(1)
    elif test_result["status"] != "ok":
        print(f"  WARNING: Test download returned: {test_result}")
        print("  Proceeding anyway...")

    # Download with thread pool
    log = {}
    completed = 0
    failed = 0
    max_workers = args.workers if hasattr(args, "workers") else 3
    delay = args.delay if hasattr(args, "delay") else 0.5

    def download_with_delay(item):
        url, filepath, post_id, idx = item
        time.sleep(delay)
        result = download_one(url, filepath, cookie)
        result["post_id"] = post_id
        result["index"] = idx
        return (f"{post_id}_{idx}", result)

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Skip first item if test was successful
        start = 0 if test_result["status"] != "ok" else 1
        if test_result["status"] == "ok":
            log[f"{queue[0][2]}_{queue[0][3]}"] = test_result
            completed += 1

        futures = {
            executor.submit(download_with_delay, item): item
            for item in queue[start:]
        }
        total = len(queue)
        for future in as_completed(futures):
            key, result = future.result()
            log[key] = result
            if result["status"] == "ok":
                completed += 1
            else:
                failed += 1
            done = completed + failed + (1 if start == 1 else 0) - 1
            if done % 20 == 0 or done == total:
                print(f"  Progress: {done}/{total} ({completed} ok, {failed} failed)")

    # Write log
    with open(DOWNLOAD_LOG, "w") as f:
        json.dump(log, f, indent=2)

    print(f"\n  Download complete: {completed} ok, {failed} failed")
    print(f"  Log: {DOWNLOAD_LOG}")
    print("Phase 3 complete.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Prepare student dataset from MCL export.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("score", help="Score all posts for AI slop likelihood")
    sub.add_parser("select", help="Sample ~420 posts for student dataset")

    dl = sub.add_parser("download", help="Download multimedia for selected posts")
    dl.add_argument("--cookie", required=True, help="Cookie header string from MCL session")
    dl.add_argument("--workers", type=int, default=3, help="Download threads (default: 3)")
    dl.add_argument("--delay", type=float, default=0.5, help="Delay between downloads in seconds (default: 0.5)")

    all_cmd = sub.add_parser("all", help="Run score + select + download")
    all_cmd.add_argument("--cookie", required=True, help="Cookie header string from MCL session")
    all_cmd.add_argument("--workers", type=int, default=3, help="Download threads (default: 3)")
    all_cmd.add_argument("--delay", type=float, default=0.5, help="Delay between downloads in seconds (default: 0.5)")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    if args.command == "score":
        cmd_score(args)
    elif args.command == "select":
        cmd_select(args)
    elif args.command == "download":
        cmd_download(args)
    elif args.command == "all":
        rows = cmd_score(args)
        for r in rows:
            r["slop_score"] = safe_int(r.get("slop_score"))
        selected = select_dataset(rows)
        for row in selected:
            try:
                mm = json.loads(row.get("multimedia", "[]"))
                row["multimedia_count"] = len(mm)
            except (json.JSONDecodeError, TypeError):
                row["multimedia_count"] = 0
        fieldnames = [
            "id", "post_owner.name", "text", "content_type", "creation_time",
            "statistics.reaction_count", "statistics.like_count",
            "statistics.love_count", "statistics.haha_count",
            "statistics.wow_count", "statistics.sad_count",
            "statistics.angry_count", "statistics.care_count",
            "statistics.comment_count", "statistics.share_count",
            "statistics.views",
            "multimedia_count", "slop_score", "slop_category", "is_slop",
        ]
        write_csv(METADATA_CSV, selected, fieldnames)
        cmd_download(args)


if __name__ == "__main__":
    main()
