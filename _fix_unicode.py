import re

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all r'''...''' raw strings and fix \uXXXX inside them
    # In raw strings, \\uXXXX becomes literal chars backslash+u+XXXX
    # We need to convert these to actual unicode codepoints

    fixed = content

    # Replace \\u{XXXX} (4-digit) patterns in raw strings - actually these come from
    # the Python raw string having \\u -> which means the literal text is \\u{XXXX}
    # But in the file as written, we have '\\u{1F38B}' as text (raw string)
    # Actually wait - the Python raw string r''' has '\\u{...}'' in it
    # But when we write to file, those 2 chars \ and u become written
    # So the file contains the TEXT '\\u{1F38B}' (6 chars)
    # Dart sees this as ESCAPE ERROR because \u must be followed by 4 hex digits
    # The fix: replace all occurrences of literal backslash-u in the output

    # Count the problem
    count = content.count('\\u{')
    count2 = content.count('\\u')
    print(f'{path}: found {count} \\u{{ patterns, {count2} \\u patterns')

    # Replace literal backslash-u sequences with actual unicode
    def replace_4(m):
        hex_val = m.group(1)
        return chr(int(hex_val, 16))

    def replace_6(m):
        hex_val = m.group(1)
        return chr(int(hex_val, 16))

    # Fix \u{XXXX} (6 digits)
    fixed = re.sub(r'\\u\{([0-9A-Fa-f]{4,6})\}', replace_6, fixed)
    # Fix \uXXXX (4 digits)
    fixed = re.sub(r'\\u([0-9A-Fa-f]{4})', replace_4, fixed)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(fixed)
    print(f'Fixed {path}')

for p in [
    r'C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\lib\features\shop\fate_draw_flow.dart',
    r'C:\Users\85932\.qclaw\workspace\software-factory\projects\kouming\lib\features\shop\fulfill_ceremony.dart',
]:
    fix_file(p)
