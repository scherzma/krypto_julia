import os
from pathlib import Path

# Get the directory where the script is located
SCRIPT_DIR = Path(__file__).parent.absolute()

# Configuration
output_file = SCRIPT_DIR / "source_files_content.txt"
file_extensions = {'.cpp', '.h', '.txt', '.jl', 'kauma'}  # Using set for faster lookups
blacklist_dirs = {'jl', 'build.jl', 'Krypto', '.git', 'node_modules', 'build', 'cmake-build-debug', '.vscode', '.idea', 'venv', 'MyAppCompiled', '.venv', 'testing'}


def write_structure(file, path, prefix="", include_files=True):
    """Write directory structure with proper indentation"""
    with open(file, 'a', encoding='utf-8') as f:
        f.write(f'{prefix}📁 {path.name}/\n')

    # Process directories first
    dirs = [d for d in sorted(path.iterdir()) if d.is_dir() and d.name not in blacklist_dirs]
    for directory in dirs:
        write_structure(file, directory, prefix + "    ")

    # Then process files if requested
    if include_files:
        files = [f for f in sorted(path.iterdir()) if f.is_file()]
        for file_path in files:
            # Skip the output file itself
            if file_path.name == output_file.name:
                continue
            with open(output_file, 'a', encoding='utf-8') as f:
                if file_path.suffix in file_extensions:
                    f.write(f'{prefix}    📄 {file_path.name} (Content follows below)\n')
                else:
                    f.write(f'{prefix}    📄 {file_path.name}\n')

def main():
    # Change to script directory
    os.chdir(SCRIPT_DIR)

    # Clear or create output file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("Directory Structure:\n")
        f.write("===================\n\n")

    # Write directory structure
    write_structure(output_file, SCRIPT_DIR)

    # Now append file contents for matching files
    with open(output_file, 'a', encoding='utf-8') as f:
        f.write("\n\nFile Contents:\n")
        f.write("=============\n")

    for root, dirs, files in os.walk(SCRIPT_DIR, topdown=True):
        # Skip blacklisted directories
        dirs[:] = [d for d in dirs if d not in blacklist_dirs]

        # Process files
        for file in sorted(files):
            # Skip the output file itself
            if file == output_file.name or file == 'script.py':
                continue

            if any(file.endswith(ext) for ext in file_extensions):
                file_path = Path(root) / file

                try:
                    with open(output_file, 'a', encoding='utf-8') as out_f:
                        out_f.write('\n\n===========================================\n')
                        out_f.write(f'File: {file_path.relative_to(SCRIPT_DIR)}\n')
                        out_f.write('===========================================\n\n')

                        # Read and write file content
                        with open(file_path, 'r', encoding='utf-8') as in_f:
                            out_f.write(in_f.read())
                except UnicodeDecodeError:
                    print(f"Warning: Could not read {file_path} - not a text file or unknown encoding")
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

    print(f"Directory structure and file contents have been written to {output_file}")

if __name__ == "__main__":
    main()