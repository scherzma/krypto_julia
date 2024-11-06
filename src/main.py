import json
import sys
from typing import Dict, Any

from src.operations.padding_oracle_chaggpt import padding_oracle as padding_oracle_chaggpt
from src.operations.padding_oracle import padding_oracle
from src.operations.arithmetic import add_numbers, subtract_numbers
from src.operations.polynomial import poly2block, block2poly
from src.operations.galois import gfmul
from src.operations.encryption import sea128, xex, gcm_encrypt, gcm_decrypt
from src.testing.TestResultTracker import TestResultTracker


def load_testcases(file_path: str) -> Dict[str, Any]:
    """Load test cases from a JSON file."""
    with open(file_path, "r") as f:
        return json.load(f)


def print_changes(changes: Dict[str, Any]):
    """Pretty print test result changes."""
    if changes["status"] == "first_run":
        print("\n🆕 First test run - establishing baseline")
        return

    if changes["status"] == "no_changes":
        print("\n✅ All tests match previous run")
        return

    print("\n⚠️  Changes detected in test results:")
    for test_id, change in changes["changes"].items():
        if "status" in change and change["status"] == "new_test":
            print(f"\n📝 New test: {test_id}")
            continue

        print(f"\n🔄 Test '{test_id}' changed:")
        print(f"  Previous: {change['previous']}")
        print(f"  Current:  {change['current']}")
        if change.get("is_known_false"):
            print("  (Known false positive)")


def main():
    """Main entry point for the application."""
    file = "./sample.json"
    is_test_mode = True
    view_test = None

    # Debug configuration - set to None to disable
    DEBUG_VIEW_TESTS = [
        "gcm_decrypt_aes128",
        "gcm_encrypt",
        #"gcm_encrypt_sea128"
    ]

    # Parse command line arguments
    if len(sys.argv) > 1:
        is_test_mode = False
        file = sys.argv[1]
        # Check for --view argument
        if len(sys.argv) > 2 and sys.argv[2] == "--view" and len(sys.argv) > 3:
            view_test = sys.argv[3]
            is_test_mode = True

    # Initialize test tracker early to ensure it's available for all testing scenarios
    tracker = TestResultTracker() if is_test_mode else None

    # Handle view test request first
    if view_test:
        if tracker:
            tracker.print_test_history(view_test)
            return
        else:
            print("Error: Test tracking is not enabled")
            return

    # Map actions to their corresponding functions
    action_functions = {
        "add_numbers": add_numbers,
        "subtract_numbers": subtract_numbers,
        "poly2block": poly2block,
        "block2poly": block2poly,
        "gfmul": gfmul,
        "sea128": sea128,
        "xex": xex,
        "gcm_encrypt": gcm_encrypt,
        "gcm_decrypt": gcm_decrypt,
        "padding_oracle": padding_oracle_chaggpt, # padding_oracle,
    }

    # Load and process test cases
    data = load_testcases(file)
    response = {}

    for id, testcase in data["testcases"].items():
        action = testcase["action"]
        func = action_functions.get(action)
        if func:
            response[id] = func(testcase)
        else:
            print(f"Warning: Unknown action '{action}' for testcase {id}")

    if is_test_mode and tracker:
        # Show test results
        changes = tracker.compare_results(response)
        tracker.print_changes(changes)
        tracker.save_run(response, file)

        # Debug: View specific test results if configured and tests exist
        if DEBUG_VIEW_TESTS:
            print("\n🔍 Debug Views:")
            for test_id in DEBUG_VIEW_TESTS:
                print(f"\n{'=' * 50}")
                tracker.print_test_history(test_id, 1)
    else:
        # Original behavior - just output JSON
        print(json.dumps({"responses": response}, indent=1))


if __name__ == "__main__":
    main()