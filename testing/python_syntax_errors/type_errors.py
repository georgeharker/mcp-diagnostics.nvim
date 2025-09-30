"""
Python file with type-related errors and mismatches.
This should generate type checking errors and runtime type issues.
"""

from typing import List, Dict, Optional, Union
import json


class TypeErrorExamples:
    """Class demonstrating various type errors."""
    
    def __init__(self):
        self.data: Dict[str, int] = {"count": 0}
        self.items: List[str] = []
    
    def string_number_confusion(self) -> int:
        """Mix strings and numbers inappropriately."""
        # Type error: trying to add string to number
        result = "10" + 5  # TypeError: unsupported operand types
        
        # Type error: comparing string to number
        if "100" > 50:  # This works in Python but is semantically wrong
            print("String comparison issue")
        
        # Type error: using string as number
        return "not a number"  # Return type should be int
    
    def list_dict_confusion(self) -> None:
        """Confuse list and dictionary operations."""
        my_list = [1, 2, 3, 4, 5]
        my_dict = {"a": 1, "b": 2}
        
        # Type error: using dictionary method on list
        try:
            value = my_list.get("key")  # AttributeError: list has no get method
        except AttributeError:
            pass
        
        # Type error: using list method on dictionary
        try:
            my_dict.append("new_item")  # AttributeError: dict has no append method
        except AttributeError:
            pass
        
        # Type error: indexing dictionary with integer (might work sometimes)
        try:
            item = my_dict[0]  # KeyError unless 0 is a key
        except KeyError:
            pass
        
        # Type error: iterating incorrectly
        for item in my_dict:  # This gives keys, not key-value pairs
            print(f"Value: {my_dict[item].upper()}")  # Assuming values are strings (they're not)
    
    def none_value_errors(self) -> str:
        """Demonstrate None-related type errors."""
        value: Optional[str] = None
        
        # Type error: calling method on None
        length = value.upper()  # AttributeError: NoneType has no method upper
        
        # Type error: using None in arithmetic
        result = value + " suffix"  # TypeError: unsupported operand types
        
        # Type error: indexing None
        char = value[0]  # TypeError: NoneType object is not subscriptable
        
        return length  # This won't reach here due to errors above
    
    def function_call_errors(self) -> None:
        """Demonstrate function call type errors."""
        # Wrong number of arguments
        result1 = self.takes_two_args("only_one")  # Missing required argument
        
        # Wrong type of arguments
        result2 = self.takes_string_arg(123)  # Should be string, not int
        
        # Calling non-callable
        my_string = "hello"
        result3 = my_string()  # TypeError: str object is not callable
        
        # Using wrong method
        numbers = [1, 2, 3]
        result4 = numbers.split(",")  # AttributeError: list has no split method
    
    def takes_two_args(self, arg1: str, arg2: str) -> str:
        """Function that requires two arguments."""
        return f"{arg1} and {arg2}"
    
    def takes_string_arg(self, text: str) -> int:
        """Function that expects string argument."""
        return len(text)
    
    def iteration_errors(self) -> None:
        """Demonstrate iteration type errors."""
        # Trying to iterate over non-iterable
        number = 42
        for item in number:  # TypeError: int object is not iterable
            print(item)
        
        # Wrong unpacking
        pairs = [(1, 2), (3, 4), (5, 6)]
        for single_value in pairs:  # Should unpack to two values
            x, y, z = single_value  # ValueError: not enough values to unpack
            print(f"{x}, {y}, {z}")
        
        # String iteration assumption
        data = "12345"
        total = 0
        for char in data:
            total += char  # TypeError: unsupported operand types (int + str)
    
    def comparison_errors(self) -> bool:
        """Demonstrate comparison type errors."""
        # Comparing incompatible types
        result1 = "10" < 5  # This works but is misleading
        result2 = [1, 2] > "string"  # TypeError in Python 3
        result3 = {"key": "value"} == [1, 2, 3]  # Always False, likely not intended
        
        # Using 'is' instead of '=='
        number1 = 1000
        number2 = 1000
        same = number1 is number2  # Might be False due to object identity
        
        return result1 and result2 and result3 and same
    
    def assignment_errors(self) -> None:
        """Demonstrate assignment type errors."""
        # Assigning wrong types to typed variables
        self.data: Dict[str, int] = "not a dictionary"  # Type mismatch
        self.items: List[str] = {"not": "a list"}  # Type mismatch
        
        # Multiple assignment errors
        a, b = "single_value"  # ValueError: not enough values to unpack
        x, y, z = [1, 2]  # ValueError: not enough values to unpack
        
        # Attribute assignment on wrong types
        my_string = "hello"
        my_string.new_attribute = "value"  # AttributeError: can't set attribute
    
    def json_type_errors(self) -> Dict:
        """Demonstrate JSON-related type errors."""
        # Assuming JSON structure without validation
        json_string = '{"name": "Alice", "age": 30}'
        data = json.loads(json_string)
        
        # Type assumption errors
        name = data["name"].upper()  # Assumes name is string (it is here, but no validation)
        age_next_year = data["age"] + 1  # Assumes age is number (it is, but no validation)
        
        # Accessing non-existent keys without safety
        address = data["address"]["street"]  # KeyError: address doesn't exist
        
        # Wrong method on JSON data
        serialized = data.encode("utf-8")  # AttributeError: dict has no encode method
        
        return data


class InvalidInheritance(int, str):  # TypeError: multiple bases have instance lay-out conflict
    """Invalid multiple inheritance."""
    pass


class WrongMethodOverride:
    """Class with incorrect method overrides."""
    
    def process_data(self, data: List[str]) -> int:
        """Original method signature."""
        return len(data)


class BrokenChild(WrongMethodOverride):
    """Child class that breaks parent's contract."""
    
    def process_data(self, data: str, extra_param: int = 5) -> str:  # Incompatible signature
        """Overridden method with incompatible signature."""
        return f"Processed: {data}"


def function_with_type_errors():
    """Function demonstrating various type errors."""
    
    # Mixed operations
    mixed = "text" * 2.5  # TypeError: can't multiply string by float
    
    # Wrong container operations
    my_set = {1, 2, 3}
    my_set[0] = "new_value"  # TypeError: set object does not support item assignment
    
    # File operations without proper handling
    with open("nonexistent.txt", "r") as f:  # FileNotFoundError
        content = f.read()
        number = int(content)  # ValueError if content is not numeric
        result = number / 0  # ZeroDivisionError
    
    return mixed, number, result


def generic_type_confusion():
    """Function with generic type confusion."""
    from typing import TypeVar, Generic
    
    T = TypeVar('T')
    
    class Container(Generic[T]):
        def __init__(self, item: T):
            self.item = item
        
        def get_item(self) -> T:
            return self.item
    
    # Type confusion with generics
    string_container: Container[str] = Container(123)  # Type mismatch
    number_container: Container[int] = Container("text")  # Type mismatch
    
    # Wrong type operations
    result1 = string_container.get_item().upper()  # Will fail if item is int
    result2 = number_container.get_item() + 10  # Will fail if item is str
    
    return result1, result2


def async_type_errors():
    """Async/await type errors."""
    import asyncio
    
    async def async_function() -> str:
        await asyncio.sleep(1)
        return "done"
    
    # Type error: calling async function without await
    result = async_function()  # Returns coroutine, not string
    
    # Type error: awaiting non-awaitable
    await "not awaitable"  # SyntaxError: await outside async function (in sync context)
    
    return result.upper()  # AttributeError: coroutine has no upper method


if __name__ == "__main__":
    examples = TypeErrorExamples()
    
    # All of these will cause various type errors
    examples.string_number_confusion()
    examples.list_dict_confusion()
    examples.none_value_errors()
    examples.function_call_errors()
    examples.iteration_errors()
    examples.comparison_errors()
    examples.assignment_errors()
    examples.json_type_errors()
    
    function_with_type_errors()
    generic_type_confusion()
    # async_type_errors()  # Can't run in sync context