def add_numbers(case: dict) -> dict:
    """Add two numbers from the case arguments."""
    return {"sum": case["arguments"]["number1"] + case["arguments"]["number2"]}

def subtract_numbers(case: dict) -> dict:
    """Subtract two numbers from the case arguments."""
    return {"difference": case["arguments"]["number1"] - case["arguments"]["number2"]}