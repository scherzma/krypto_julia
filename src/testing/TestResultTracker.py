import json
import os
from typing import Dict, Any, List, Optional
from datetime import datetime


class TestResultTracker:
    def __init__(self, history_file: str = "test_history.results", max_history: int = 20):
        """
        Initialize TestResultTracker

        Args:
            history_file: Path to history file
            max_history: Maximum number of test runs to keep in history
        """
        self.history_file = history_file
        self.max_history = max_history
        self.history = self._load_history()
        self.current_results = {}
        self._trim_history()

    def _load_history(self) -> Dict[str, Any]:
        """Load test history from file, create if doesn't exist."""
        if os.path.exists(self.history_file):
            try:
                with open(self.history_file, 'r') as f:
                    return json.load(f)
            except json.JSONDecodeError:
                return {"known_false_positives": {}, "test_runs": []}
        return {"known_false_positives": {}, "test_runs": []}

    def _save_history(self):
        """Save test history to file."""
        self._trim_history()  # Ensure we're within limits before saving
        with open(self.history_file, 'w') as f:
            json.dump(self.history, f, indent=2)

    def _trim_history(self):
        """Trim history to keep only the most recent runs."""
        if len(self.history["test_runs"]) > self.max_history:
            excess = len(self.history["test_runs"]) - self.max_history
            self.history["test_runs"] = self.history["test_runs"][excess:]
            return True
        return False

    def get_test_result(self, test_id: str) -> Optional[Dict[str, Any]]:
        """Get the most recent result for a specific test."""
        if not self.current_results:
            if self.history["test_runs"]:
                self.current_results = self.history["test_runs"][-1]["results"]

        return self.current_results.get(test_id)

    def get_result_history(self, test_id: str, limit: int = None) -> List[Dict[str, Any]]:
        """Get the history of results for a specific test."""
        history = []
        for run in reversed(self.history["test_runs"]):
            if test_id in run["results"]:
                history.append({
                    "timestamp": run["timestamp"],
                    "result": run["results"][test_id],
                    "source_file": run["source_file"]
                })
            if limit and len(history) >= limit:
                break
        return history

    def print_test_history(self, test_id: str, limit: int = 5):
        """Print the history of a specific test with timestamps."""
        history = self.get_result_history(test_id, limit)
        if not history:
            print(f"\n❌ No history found for test '{test_id}'")
            return

        print(f"\n📜 History for test '{test_id}' (last {len(history)} runs):")
        for i, entry in enumerate(history, 1):
            timestamp = datetime.fromisoformat(entry["timestamp"]).strftime("%Y-%m-%d %H:%M:%S")
            print(f"\n{i}. Run at {timestamp}")
            print(f"   Result: {json.dumps(entry['result'], indent=2)}")
            print(f"   Source: {entry['source_file']}")

    def compare_results(self, current_results: Dict[str, Any]) -> Dict[str, Any]:
        """Compare current results with previous runs and return analysis."""
        self.current_results = current_results

        if not self.history["test_runs"]:
            return {"status": "first_run", "changes": {}}

        last_run = self.history["test_runs"][-1]["results"]
        changes = {}

        for test_id, result in current_results.items():
            if test_id in last_run:
                if last_run[test_id] != result:
                    history = self.get_result_history(test_id, 3)
                    changes[test_id] = {
                        "previous": last_run[test_id],
                        "current": result,
                        "is_known_false": test_id in self.history["known_false_positives"],
                        "recent_history": history[1:] if len(history) > 1 else []
                    }
            else:
                changes[test_id] = {
                    "status": "new_test",
                    "current": result
                }

        return {
            "status": "changes_detected" if changes else "no_changes",
            "changes": changes
        }

    def print_changes(self, changes: Dict[str, Any]):
        """Pretty print test result changes with history."""
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
                print(f"  Result: {json.dumps(change['current'], indent=2)}")
                continue

            print(f"\n🔄 Test '{test_id}' changed:")
            print(f"  Current:  {json.dumps(change['current'], indent=2)}")
            print(f"  Previous: {json.dumps(change['previous'], indent=2)}")

            if change.get("recent_history"):
                print("  Recent history:")
                for hist in change["recent_history"]:
                    timestamp = datetime.fromisoformat(hist["timestamp"]).strftime("%Y-%m-%d %H:%M:%S")
                    print(f"    {timestamp}: {json.dumps(hist['result'], indent=2)}")

            if change.get("is_known_false"):
                print("  (Known false positive)")

    def save_run(self, results: Dict[str, Any], source_file: str):
        """Save current test run with timestamp and source file."""
        self.current_results = results
        run_data = {
            "timestamp": datetime.now().isoformat(),
            "source_file": source_file,
            "results": results
        }
        self.history["test_runs"].append(run_data)
        if self._trim_history():
            print(f"\n📊 History trimmed to last {self.max_history} runs")
        self._save_history()

    def mark_false_positive(self, test_id: str, reason: str = ""):
        """Mark a test result as a known false positive."""
        self.history["known_false_positives"][test_id] = {
            "marked_at": datetime.now().isoformat(),
            "reason": reason
        }
        self._save_history()

    def unmark_false_positive(self, test_id: str):
        """Remove a test from known false positives."""
        if test_id in self.history["known_false_positives"]:
            del self.history["known_false_positives"][test_id]
            self._save_history()

    def clear_history(self):
        """Clear all test history while preserving false positives."""
        self.history["test_runs"] = []
        self._save_history()
        print("\n🧹 Test history cleared")