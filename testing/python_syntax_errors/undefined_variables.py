"""
Python file with undefined variable usage and scope errors.
This should generate NameError and UnboundLocalError type issues.
"""

from typing import List, Dict, Optional


class UndefinedVariableExamples:
    """Class demonstrating undefined variable issues."""
    
    def __init__(self):
        self.initialized = True
    
    def use_undefined_global(self) -> None:
        """Use undefined global variables."""
        # Using completely undefined variable
        print(f"Undefined value: {undefined_global_var}")
        
        # Using variable that might exist elsewhere
        total = existing_var + 10  # NameError if existing_var not defined
        
        # Using typo in variable name
        self.initalized = False  # Typo: should be 'initialized'
        
        # Using undefined constants
        max_size = MAX_BUFFER_SIZE  # NameError if not defined
        config = DEFAULT_CONFIG     # NameError if not defined
    
    def use_undefined_local(self) -> int:
        """Use undefined local variables."""
        # Using variable before definition
        result = local_var * 2  # NameError: local_var used before definition
        local_var = 10
        
        # Conditional definition leading to potential undefined usage
        if False:  # This condition never executes
            conditional_var = 42
        
        # Using conditionally defined variable
        print(f"Conditional value: {conditional_var}")  # NameError if condition was False
        
        return result
    
    def scope_confusion(self) -> None:
        """Demonstrate scope-related undefined variables."""
        for i in range(5):
            loop_var = i * 2
        
        # Using loop variable outside its intended scope
        print(f"Loop variable after loop: {loop_var}")  # This works in Python, but misleading
        
        # Using loop index after loop
        print(f"Index after loop: {i}")  # This works but can be confusing
        
        # Try to use variables from different scopes
        def inner_function():
            inner_var = "inner"
            # This would cause NameError if called from outside
            return outer_var  # NameError if outer_var not defined in enclosing scope
        
        # Call inner function
        result = inner_function()
        
        # Try to use inner variable from outer scope
        print(f"Inner variable: {inner_var}")  # NameError: inner_var not defined in this scope
    
    def typo_variables(self) -> None:
        """Common typos in variable names."""
        # Correct variable
        user_name = "Alice"
        user_age = 30
        user_email = "alice@example.com"
        
        # Typos in usage
        print(f"Name: {user_nane}")      # Typo: 'nane' instead of 'name'
        print(f"Age: {user_ag}")         # Typo: 'ag' instead of 'age'
        print(f"Email: {user_emai}")     # Typo: 'emai' instead of 'email'
        
        # Capitalization errors
        print(f"Name: {User_Name}")      # Wrong case
        print(f"Age: {USER_AGE}")        # Wrong case
        
        # Missing underscores
        print(f"Email: {useremail}")     # Missing underscore
    
    def method_name_errors(self) -> None:
        """Errors in method and attribute names."""
        # Typo in method name
        self.initalize()  # Typo: should be 'initialize' if it exists
        
        # Wrong attribute access
        value = self.uninitalized  # Typo: should be 'initialized' with wrong prefix
        
        # Non-existent method calls
        self.nonexistent_method()  # AttributeError: method doesn't exist
        
        # Typos in built-in function names
        result = leng([1, 2, 3])  # NameError: should be 'len'
        maximum = maxx(1, 2, 3)   # NameError: should be 'max'


def function_with_undefined_vars():
    """Function using undefined variables."""
    # Using global that doesn't exist
    global GLOBAL_CONSTANT
    value = GLOBAL_CONSTANT  # NameError if not defined
    
    # Using parameter that wasn't passed
    print(f"Missing param: {missing_parameter}")  # NameError
    
    # Typos in function names
    result = printt("Hello")  # NameError: should be 'print'
    data = dictt()           # NameError: should be 'dict'
    
    return value, result, data


def variable_before_assignment():
    """Use variable before it's assigned (UnboundLocalError)."""
    print(f"Value before assignment: {x}")  # UnboundLocalError
    x = 10
    print(f"Value after assignment: {x}")


def conditional_assignment_error():
    """Variable assigned conditionally but used unconditionally."""
    import random
    
    if random.random() > 0.5:
        success_value = "Success!"
    
    # This might cause NameError if condition was False
    print(f"Result: {success_value}")


def loop_variable_confusion():
    """Confusion with loop variables."""
    numbers = [1, 2, 3, 4, 5]
    
    # Use enumerate index incorrectly
    for idx, value in enumerate(numbers):
        if value > 3:
            break
    
    # Try to use variables that might not be set
    print(f"Found value {value} at index {idx}")  # Might be OK or might not be set
    
    # Use wrong variable name from loop
    for item in numbers:
        processed = item * 2
    
    # Typo in loop variable
    print(f"Last processed: {procesed}")  # Typo: missing 's'


def nested_scope_errors():
    """Errors related to nested function scopes."""
    outer_var = "outer"
    
    def inner_function():
        # Try to modify outer variable without nonlocal
        outer_var = "modified"  # Creates local variable, doesn't modify outer
        
        # Use undefined variable from inner scope
        print(f"Undefined inner: {undefined_inner_var}")
        
    def another_inner():
        # Try to access variable from sibling function
        print(f"From sibling: {outer_var}")  # This works
        print(f"From sibling undefined: {undefined_inner_var}")  # NameError
    
    inner_function()
    another_inner()


def import_name_errors():
    """Errors related to import names and module attributes."""
    import os
    import sys
    
    # Typos in module names
    current_dir = OSs.getcwd()  # NameError: should be 'os'
    platform = syss.platform   # NameError: should be 'sys'
    
    # Non-existent module attributes
    version = os.version        # AttributeError: os has no 'version'
    path_sep = sys.path_separator  # AttributeError: should be 'pathsep'
    
    # Wrong import usage
    from json import load
    # But try to use loads (not imported)
    data = loads('{"key": "value"}')  # NameError: loads not imported


def class_attribute_errors():
    """Errors with class and instance attributes."""
    
    class ExampleClass:
        class_var = "class_variable"
        
        def __init__(self):
            self.instance_var = "instance_variable"
        
        def method_with_errors(self):
            # Typo in class variable access
            print(self.class_varr)  # AttributeError: typo in 'class_var'
            
            # Typo in instance variable
            print(self.instance_varr)  # AttributeError: typo in 'instance_var'
            
            # Try to access non-existent attribute
            print(self.nonexistent_attr)  # AttributeError
            
            # Wrong attribute access pattern
            print(ExampleClass.instance_var)  # AttributeError: instance var on class
    
    obj = ExampleClass()
    
    # Access errors from outside
    print(obj.class_varr)      # AttributeError: typo
    print(obj.missing_attr)    # AttributeError: doesn't exist
    
    # Wrong class access
    print(ExampleClass.instance_var)  # AttributeError


def exception_handling_errors():
    """Errors in exception handling variable scope."""
    try:
        x = 1 / 0
    except ZeroDivisionError as e:
        error_msg = str(e)
    
    # Try to use exception variable outside except block
    print(f"Error was: {e}")  # NameError: e not defined outside except block
    
    # Try to use variable defined in except block
    print(f"Error message: {error_msg}")  # This works if except block executed
    
    # But what if no exception occurred?
    try:
        y = 10 / 2  # No exception
    except ZeroDivisionError:
        safe_result = "No division by zero"
    
    # This might cause NameError if no exception occurred
    print(f"Safety message: {safe_result}")


# Global scope undefined usage
print(f"Global undefined: {global_undefined_var}")  # NameError

# Typos in global scope
def process_data():
    return "processed"

# Call with typo
result = proces_data()  # NameError: typo in function name


# Class definition with undefined base
class DerivedClass(UndefinedBaseClass):  # NameError: base class not defined
    pass


if __name__ == "__main__":
    # All these will cause various NameError and UnboundLocalError issues
    examples = UndefinedVariableExamples()
    
    examples.use_undefined_global()
    examples.use_undefined_local()
    examples.scope_confusion()
    examples.typo_variables()
    examples.method_name_errors()
    
    function_with_undefined_vars()
    variable_before_assignment()
    conditional_assignment_error()
    loop_variable_confusion()
    nested_scope_errors()
    import_name_errors()
    class_attribute_errors()
    exception_handling_errors()