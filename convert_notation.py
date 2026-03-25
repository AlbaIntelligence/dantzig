import re
import sys

BASE = "/home/emmanuel/.Private.Sync.Clear/Documents/Work/Alba/Synced_projects/Alba_CashWork/third_party/dantzig/"

# LP decision variable names declared with variables("name", ...) in the docs
LP_VARS = sorted([
    'queen_position',
    'queen2d', 'queen3d',
    'use_machine',
    'production', 'produce', 'inventory', 'inv',
    'assign',
    'ship', 'flow', 'alloc',
    'select',
    'qty',
    'val',
    'x', 'y', 'z',
], key=len, reverse=True)  # Longer names first to avoid partial matches

def convert_parens_to_brackets(text):
    """Convert var(a, b, c) -> var[a][b][c] for LP variable names."""
    var_alt = '|'.join(re.escape(v) for v in LP_VARS)
    pattern = re.compile(r'\b(' + var_alt + r')\(([^()]*)\)')

    def replacer(m):
        varname = m.group(1)
        args_raw = m.group(2)
        args = [a.strip() for a in args_raw.split(',')]
        if not args or (len(args) == 1 and args[0] == ''):
            return m.group(0)  # No args? Leave as-is
        brackets = ''.join(f'[{a}]' for a in args if a != '')
        return varname + brackets

    return pattern.sub(replacer, text)

files = [
    "docs/user/tutorial/basics.md",
    "docs/user/tutorial/comprehensive.md",
    "docs/user/quickstart.md",
    "docs/user/reference/dsl-syntax.md",
    "docs/user/reference/model-parameters.md",
    "docs/user/reference/syntax/constraints.md",
    "docs/user/reference/syntax/wildcards.md",
    "docs/user/reference/syntax/objectives.md",
    "docs/user/reference/syntax/variables.md",
    "docs/user/reference/expressions.md",
    "docs/user/reference/DSL_SYNTAX_EXAMPLES.md",
    "docs/user/reference/advanced/error-handling.md",
    "docs/user/reference/advanced/wildcards-and-nested-maps.md",
    "docs/user/reference/advanced/implementation-requirements.md",
    "docs/user/guides/modeling-patterns.md",
    "docs/user/guides/troubleshooting.md",
    "docs/user/guides/DEPRECATION_NOTICE.md",
    "README.md",
]

for f in files:
    path = BASE + f
    try:
        with open(path, 'r') as fh:
            original = fh.read()
        converted = convert_parens_to_brackets(original)
        if converted != original:
            with open(path, 'w') as fh:
                fh.write(converted)
            # Count changes
            import difflib
            diff = list(difflib.unified_diff(original.splitlines(), converted.splitlines(), lineterm=''))
            added = sum(1 for l in diff if l.startswith('+') and not l.startswith('+++'))
            removed = sum(1 for l in diff if l.startswith('-') and not l.startswith('---'))
            print(f"Modified {f}: +{added}/-{removed} lines")
        else:
            print(f"No changes: {f}")
    except FileNotFoundError:
        print(f"NOT FOUND: {f}")

print("Done.")
