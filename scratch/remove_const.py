import os
import re

patterns = [
    (r'\bconst\s+BorderSide\(', 'BorderSide('),
    (r'\bconst\s+TextStyle\(', 'TextStyle('),
    (r'\bconst\s+Divider\(', 'Divider('),
    (r'\bconst\s+Icon\(', 'Icon('),
    (r'\bconst\s+ColorScheme\.light\(', 'ColorScheme.light('),
    (r'\bconst\s+ColorScheme\.dark\(', 'ColorScheme.dark('),
    (r'\bconst\s+LinearGradient\(', 'LinearGradient('),
    (r'\bconst\s+TextButtonThemeData\(', 'TextButtonThemeData('),
    (r'\bconst\s+ElevatedButtonThemeData\(', 'ElevatedButtonThemeData('),
    (r'\bconst\s+OutlinedButtonThemeData\(', 'OutlinedButtonThemeData('),
    (r'\bconst\s+CardThemeData\(', 'CardThemeData('),
    (r'\bconst\s+SnackBarThemeData\(', 'SnackBarThemeData('),
    (r'\bconst\s+OutlineInputBorder\(', 'OutlineInputBorder('),
    (r'\bconst\s+InputBorder\(', 'InputBorder('),
    (r'\bconst\s+Border\(', 'Border('),
    (r'\bconst\s+EdgeInsets\(', 'EdgeInsets('),
    (r'\bconst\s+BoxDecoration\(', 'BoxDecoration('),
    (r'\bconst\s+BoxShadow\(', 'BoxShadow('),
    (r'\bconst\s+InputDecorationTheme\(', 'InputDecorationTheme('),
    (r'\bconst\s+IconThemeData\(', 'IconThemeData('),
    (r'\bconst\s+ButtonStyle\(', 'ButtonStyle('),
    (r'\bconst\s+\[', '['),
    # Strip from common layouts to fix nested constant errors
    (r'\bconst\s+SizedBox\(', 'SizedBox('),
    (r'\bconst\s+Padding\(', 'Padding('),
    (r'\bconst\s+Center\(', 'Center('),
    (r'\bconst\s+Row\(', 'Row('),
    (r'\bconst\s+Column\(', 'Column('),
    (r'\bconst\s+Align\(', 'Align('),
    (r'\bconst\s+Expanded\(', 'Expanded('),
    (r'\bconst\s+Positioned\(', 'Positioned('),
    (r'\bconst\s+Container\(', 'Container('),
    (r'\bconst\s+Stack\(', 'Stack('),
    (r'\bconst\s+Card\(', 'Card('),
    (r'\bconst\s+Text\(', 'Text('),
    (r'\bconst\s+AlertDialog\(', 'AlertDialog('),
    (r'\bconst\s+PopupMenuItem\(', 'PopupMenuItem('),
    (r'\bconst\s+IconButton\(', 'IconButton('),
]

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Only process if AppConfig is referenced in the file
    if 'AppConfig' not in content:
        return

    original = content
    for pattern, repl in patterns:
        content = re.sub(pattern, repl, content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Processed: {filepath}")

def main():
    lib_path = "/Users/karlsome/Documents/GitHub/flutterApp/lib"
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
