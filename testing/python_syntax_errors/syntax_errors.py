"""
Python file with various syntax errors for testing diagnostics.
This file contains intentional syntax errors that should be caught by linters/parsers.
"""

import sys
from typing import List, Dict

# Syntax Error 1: Missing colon after function definition
def broken_function()  # Missing colon
    return "This function has no colon"


# Syntax Error 2: Incorrect indentation
class BadIndentation:
    def __init__(self):
        self.value = 10
      self.other = 20  # Wrong indentation level


# Syntax Error 3: Unmatched parentheses
def unmatched_parens():
    result = (1 + 2 + 3  # Missing closing parenthesis
    return result


# Syntax Error 4: Invalid string literals
def string_errors():
    bad_string = "This string is not closed
    another_bad = 'Mixed quotes"
    escaped_wrong = "Invalid \q escape sequence"
    return bad_string, another_bad, escaped_wrong


# Syntax Error 5: Invalid dictionary syntax
def dict_syntax_errors():
    bad_dict = {
        "key1": "value1"
        "key2": "value2"  # Missing comma
        "key3" = "value3"  # Wrong operator (= instead of :)
    }
    return bad_dict


# Syntax Error 6: Invalid list comprehension
def list_comp_errors():
    # Missing 'in' keyword
    bad_comp = [x for x range(10)]
    
    # Invalid syntax in condition
    another_bad = [x for x in range(10) if x > 5 and]  # Incomplete condition
    
    return bad_comp, another_bad


# Syntax Error 7: Invalid import statements
import sys,  # Trailing comma
from typing import List Dict  # Missing comma between imports
import json as  # Missing alias name


# Syntax Error 8: Invalid class definition
class BrokenClass(  # Missing base class name or closing parenthesis
    def method(self):
        pass


# Syntax Error 9: Invalid function parameters
def bad_params(a, b=default_value, c):  # Non-default after default parameter
    return a + b + c

def invalid_param_syntax(*args, **kwargs, extra):  # Invalid parameter order
    return args, kwargs, extra


# Syntax Error 10: Invalid operators and expressions
def operator_errors():
    # Invalid operators
    x = 10
    y = 20
    result1 = x === y  # Invalid operator (should be == or is)
    result2 = x <> y   # Obsolete operator (Python 2 style)
    result3 = x && y   # Invalid operator (should be 'and')
    result4 = x || y   # Invalid operator (should be 'or')
    
    return result1, result2, result3, result4


# Syntax Error 11: Invalid control flow
def control_flow_errors():
    x = 10
    
    # Invalid if statement
    if x > 5  # Missing colon
        print("Greater than 5")
    
    # Invalid for loop
    for i in range(10)  # Missing colon
        print(i)
    
    # Invalid while loop
    while x > 0  # Missing colon
        x -= 1


# Syntax Error 12: Invalid try-except blocks
def exception_errors():
    try  # Missing colon
        x = 1 / 0
    except ZeroDivisionError  # Missing colon
        print("Division by zero")
    finally  # Missing colon
        print("Cleanup")


# Syntax Error 13: Invalid lambda functions
def lambda_errors():
    # Missing colon in lambda
    bad_lambda = lambda x x * 2
    
    # Invalid lambda syntax
    another_bad = lambda: x, y: x + y  # Multiple parameters without proper syntax
    
    return bad_lambda, another_bad


# Syntax Error 14: Invalid decorators
@  # Incomplete decorator
def decorated_function():
    pass

@property.  # Incomplete decorator with dot
def another_decorated():
    pass


# Syntax Error 15: Invalid assignment operators
def assignment_errors():
    x = 10
    
    # Invalid augmented assignment
    x += = 5  # Double operators
    x =+ 3    # Wrong order (should be +=)
    
    # Invalid multiple assignment
    a, b, = 1, 2, 3  # Trailing comma with wrong number of values
    x, y = 1, 2, 3, 4  # Too many values


# Syntax Error 16: Invalid with statements
def with_statement_errors():
    # Missing 'as' or colon
    with open("file.txt") f  # Missing 'as' keyword
        content = f.read()
    
    # Invalid with syntax
    with open("file.txt") as f  # Missing colon
        content = f.read()


# Syntax Error 17: Invalid async/await (if not in async context)
def sync_function():
    # Using await in non-async function
    result = await some_async_function()  # SyntaxError: await outside async function
    return result


# Syntax Error 18: Invalid f-string syntax
def fstring_errors():
    name = "Alice"
    age = 30
    
    # Invalid f-string expressions
    bad_fstring = f"Name: {name} Age: {age"  # Missing closing brace
    another_bad = f"Result: {1 + 2 +}"      # Incomplete expression
    nested_bad = f"Value: {f"Inner: {name}"}"  # Invalid nested f-string (Python < 3.12)
    
    return bad_fstring, another_bad, nested_bad


# Syntax Error 19: Invalid return/yield statements
def generator_errors():
    # Invalid yield syntax
    yield  # Incomplete yield
    yield from  # Incomplete yield from
    
    # Return in generator (not necessarily an error but questionable)
    yield 1
    return "done"  # This actually became valid in Python 3.3+


# Syntax Error 20: Invalid global/nonlocal statements
def scope_errors():
    global  # Incomplete global statement
    nonlocal  # Incomplete nonlocal statement
    
    def inner():
        nonlocal undefined_var  # Variable not in enclosing scope
        undefined_var = 10


# Syntax Error 21: Invalid match statements (Python 3.10+)
def match_errors():
    value = 10
    
    # Invalid match syntax
    match value  # Missing colon
        case 1:
            print("One")
        case 2
            print("Two")  # Missing colon after case


# Syntax Error 22: Unclosed brackets and braces
def bracket_errors():
    # Unclosed list
    my_list = [1, 2, 3, 4, 5
    
    # Unclosed dictionary
    my_dict = {"key1": "value1", "key2": "value2"
    
    # Unclosed function call
    result = max(1, 2, 3, 4
    
    return my_list, my_dict, result


# This class is missing the closing of the previous function
class AnotherBrokenClass:
    def method(self):
        pass

# Missing closing quote and other issues
message = "This is a very long message that spans multiple lines
but doesn't use proper string continuation syntax and will cause
a syntax error because the quote is never closed

if __name__ == "__main__":
    # This will never run due to syntax errors above
    print("Testing syntax errors")
    broken_function()
    operator_errors()