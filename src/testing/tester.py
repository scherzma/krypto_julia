import json
from typing import Any, Dict, List, Union
from pathlib import Path


def load_json(file_path: str) -> dict:
    """
    Load JSON from file and return as dictionary.
    
    Args:
        file_path (str): Path to JSON file
    
    Returns:
        dict: Parsed JSON content
    
    Raises:
        FileNotFoundError: If file doesn't exist
        json.JSONDecodeError: If JSON is invalid
    """
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File {file_path} not found")
        raise
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {file_path}: {str(e)}")
        raise


def compare_values(path: str, value1: Any, value2: Any) -> List[str]:
    """
    Compare two values and return list of differences.
    
    Args:
        path (str): Current path in the JSON structure
        value1: First value to compare
        value2: Second value to compare
    
    Returns:
        List[str]: List of differences found
    """
    differences = []
    
    if type(value1) != type(value2):
        differences.append(f"Type mismatch at {path}:")
        differences.append(f"  - File 1: {type(value1).__name__} = {value1}")
        differences.append(f"  - File 2: {type(value2).__name__} = {value2}")
        return differences
        
    if isinstance(value1, dict):
        differences.extend(compare_dicts(path, value1, value2))
    elif isinstance(value1, list):
        differences.extend(compare_lists(path, value1, value2))
    elif value1 != value2:
        differences.append(f"Value mismatch at {path}:")
        differences.append(f"  - File 1: {value1}")
        differences.append(f"  - File 2: {value2}")
        
    return differences


def compare_dicts(path: str, dict1: Dict, dict2: Dict) -> List[str]:
    """
    Compare two dictionaries and return list of differences.
    
    Args:
        path (str): Current path in the JSON structure
        dict1: First dictionary to compare
        dict2: Second dictionary to compare
    
    Returns:
        List[str]: List of differences found
    """
    differences = []
    
    # Check for keys present in dict1 but not in dict2
    for key in dict1.keys() - dict2.keys():
        differences.append(f"Key '{key}' present in file 1 but missing in file 2 at {path}")
    
    # Check for keys present in dict2 but not in dict1
    for key in dict2.keys() - dict1.keys():
        differences.append(f"Key '{key}' present in file 2 but missing in file 1 at {path}")
    
    # Compare values for common keys
    for key in dict1.keys() & dict2.keys():
        new_path = f"{path}.{key}" if path else key
        differences.extend(compare_values(new_path, dict1[key], dict2[key]))
    
    return differences


def compare_lists(path: str, list1: List, list2: List) -> List[str]:
    """
    Compare two lists and return list of differences.
    
    Args:
        path (str): Current path in the JSON structure
        list1: First list to compare
        list2: Second list to compare
    
    Returns:
        List[str]: List of differences found
    """
    differences = []
    
    if len(list1) != len(list2):
        differences.append(f"List length mismatch at {path}:")
        differences.append(f"  - File 1: {len(list1)} items")
        differences.append(f"  - File 2: {len(list2)} items")
    
    # Compare items at each index
    for i in range(min(len(list1), len(list2))):
        differences.extend(compare_values(f"{path}[{i}]", list1[i], list2[i]))
    
    return differences


def compare_json_files(file1: str, file2: str) -> None:
    """
    Compare two JSON files and print their differences.
    
    Args:
        file1 (str): Path to first JSON file
        file2 (str): Path to second JSON file
    """
    try:
        # Load JSON files
        json1 = load_json(file1)
        json2 = load_json(file2)
        
        # Compare the JSONs
        differences = compare_values("", json1, json2)
        
        # Print results
        if differences:
            print("\nDifferences found:")
            for diff in differences:
                print(diff)
        else:
            print("\nNo differences found - JSONs are identical.")
            
    except (FileNotFoundError, json.JSONDecodeError):
        print("\nComparison failed due to above errors.")


if __name__ == "__main__":
    file1 = "./src/testing/json1.json"
    file2 = "./src/testing/json2.json"
    
    print(f"Comparing {file1} and {file2}...")
    compare_json_files(file1, file2)