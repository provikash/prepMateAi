import os

# CONFIGURATION
ROOT_DIR = "."  # current directory (your repo)
OUTPUT_FILE = "structure.txt"
MAX_DEPTH = 3  # control depth (2–3 recommended)

EXCLUDE_FOLDERS = {
    ".git",
    "__pycache__",
    "venv",
    ".dart_tool",
    "build",
    "node_modules",
    ".idea",
}

def generate_tree(startpath, prefix="", depth=0):
    if depth > MAX_DEPTH:
        return []

    lines = []
    items = sorted(os.listdir(startpath))

    # filter unwanted folders
    items = [item for item in items if item not in EXCLUDE_FOLDERS]

    for index, item in enumerate(items):
        path = os.path.join(startpath, item)
        connector = "├── " if index < len(items) - 1 else "└── "

        lines.append(prefix + connector + item)

        if os.path.isdir(path):
            extension = "│   " if index < len(items) - 1 else "    "
            lines.extend(generate_tree(path, prefix + extension, depth + 1))

    return lines


def main():
    root_name = os.path.basename(os.path.abspath(ROOT_DIR))
    tree_lines = [root_name + "/"]
    tree_lines.extend(generate_tree(ROOT_DIR))

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(tree_lines))

    print(f"✅ Structure saved to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()