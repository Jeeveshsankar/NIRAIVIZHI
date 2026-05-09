import sys
import re
import os

def remove_comments(content, file_ext):
    if file_ext in ('.dart', '.js', '.css'):
        # Strip block comments /* ... */
        content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
        
        # Split into lines to handle // carefully
        lines = content.split('\n')
        new_lines = []
        for line in lines:
            # Look for // that is not part of a URL (http:// or https://)
            # and ignore // that is preceded by a colon unless it's a URL
            # Actually, simpler: find // and check if it's in a string.
            # But let's start with a simpler regex: any // not preceded by http: or https:
            # and not being inside a quoted string is complex.
            # Let's try matching // if it's preceded by space or start of line or code-like character.
            
            # This regex looks for // that is NOT preceded by 'http:' or 'https:'
            # and may be after some code.
            # We also want to avoid deleting the rest of the line if it's a URL in a string.
            
            # Improved logic: find the first // that isn't part of a URL
            match = re.search(r'(?<!http:)(?<!https:)(?<!ftp:)//.*', line)
            if match:
                # Still might be in a string. 'Some text // more text'
                # Let's check for even counts of quotes up to the match
                start = match.start()
                until_match = line[:start]
                single_quotes = until_match.count("'") % 2
                double_quotes = until_match.count('"') % 2
                if single_quotes == 0 and double_quotes == 0:
                    line = line[:start].rstrip()
            new_lines.append(line)
        content = '\n'.join(new_lines)

    elif file_ext == '.py':
        lines = content.split('\n')
        new_lines = []
        for line in lines:
            # Ignore shebang.
            if line.startswith('#!'):
                new_lines.append(line)
                continue
            
            # Simple # removal if not in quotes
            match = re.search(r'#.*', line)
            if match:
                start = match.start()
                until_match = line[:start]
                single_quotes = until_match.count("'") % 2
                double_quotes = until_match.count('"') % 2
                if single_quotes == 0 and double_quotes == 0:
                    line = line[:start].rstrip()
            new_lines.append(line)
        content = '\n'.join(new_lines)

    elif file_ext == '.html':
        content = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)

    return content

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python remove_comments.py <file>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        sys.exit(1)
        
    _, ext = os.path.splitext(file_path)
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    new_content = remove_comments(content, ext)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Processed {file_path}")
