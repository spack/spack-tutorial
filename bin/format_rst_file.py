#!/usr/bin/env python3
"""
RST File Sentence Formatter

A tool to reformat RST files by joining sentences split across multiple lines
and ensuring each sentence is on its own line, while preserving RST structure.
"""

import argparse
import re
import sys
from pathlib import Path
from typing import List, Tuple, Optional


class RSTProcessor:
    """Processes RST files to format sentences properly."""

    def process_file(self, file_path: Path) -> bool:
        """
        Process a single RST file.

        Args:
            file_path: Path to the RST file to process

        Returns:
            True if file was changed, False if already formatted correctly
        """
        try:
            # Read the original file
            content = self._read_file(file_path)
            if content is None:
                return False

            # Process the content
            processed_content = self._process_rst_content(content)

            # Check if content changed
            if content == processed_content:
                return False  # No changes needed

            # Write back to the same file
            if self._write_file(file_path, processed_content):
                return True  # File was changed
            else:
                return False

        except Exception as e:
            print(f"error: cannot format {file_path}: {e}", file=sys.stderr)
            return False

    def _read_file(self, file_path: Path) -> Optional[str]:
        """Read file content safely."""
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read()
        except Exception as e:
            print(f"error: cannot read {file_path}: {e}", file=sys.stderr)
            return None

    def _write_file(self, file_path: Path, content: str) -> bool:
        """Write file content safely."""
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            return True
        except Exception as e:
            print(f"error: cannot write {file_path}: {e}", file=sys.stderr)
            return False

    def _process_rst_content(self, content: str) -> str:
        """
        Process RST content to format sentences properly.

        Args:
            content: Raw RST content

        Returns:
            Processed RST content
        """
        lines = content.split("\n")
        result_lines = []
        in_license_header = False
        in_directive_block = False
        directive_indent = 0

        # Check if we start with a license header
        if lines and self._is_license_header_start(lines[0]):
            in_license_header = True

        i = 0
        while i < len(lines):
            line = lines[i]

            # Handle license header
            if in_license_header:
                result_lines.append(line)
                if self._is_license_header_end(line, lines, i):
                    in_license_header = False
                i += 1
                continue

            # Handle RST lists (process entire list at once)
            if self._is_list_item(line):
                list_lines, next_i = self._collect_list(lines, i)
                result_lines.extend(list_lines)
                i = next_i
                continue

            # Handle RST tables (process entire table at once)
            if self._is_table_line(line):
                table_lines, next_i = self._collect_table(lines, i)
                result_lines.extend(table_lines)
                i = next_i
                continue

            # Handle RST directive blocks (including code blocks)
            if self._is_rst_directive_start(line):
                in_directive_block = True
                directive_indent = self._get_indent_level(line)
                result_lines.append(line)
                i += 1
                continue

            if in_directive_block:
                if self._is_directive_block_end(line, directive_indent):
                    in_directive_block = False
                else:
                    result_lines.append(line)
                    i += 1
                    continue

            # Process regular content (only when not in special blocks)
            if not in_license_header and not in_directive_block:
                paragraph_lines, next_i = self._collect_paragraph(lines, i)
                processed_lines = self._process_paragraph(paragraph_lines)
                result_lines.extend(processed_lines)
                i = next_i
            else:
                result_lines.append(line)
                i += 1

        return "\n".join(result_lines)

    def _is_license_header_start(self, line: str) -> bool:
        """Check if line starts a license header."""
        return line.strip().startswith("..") and "Copyright" in line

    def _is_license_header_end(self, line: str, lines: List[str], index: int) -> bool:
        """Check if license header ends."""
        return (
            line.strip() == ""
            and index + 1 < len(lines)
            and not lines[index + 1].strip().startswith("..")
        )

    def _is_list_item(self, line: str) -> bool:
        """Check if line is an RST list item."""
        stripped = line.strip()
        if not stripped:
            return False

        # RST list patterns
        list_patterns = [
            r"^\s*\*\s+",  # Bullet list: * item
            r"^\s*\+\s+",  # Bullet list: + item
            r"^\s*-\s+",  # Bullet list: - item
            r"^\s*\d+\.\s+",  # Numbered list: 1. item
            r"^\s*#\.\s+",  # Auto-numbered list: #. item
            r"^\s*\([a-zA-Z0-9]+\)\s+",  # Parenthesized list: (a) item
            r"^\s*[a-zA-Z]\.\s+",  # Letter list: a. item
            r"^\s*[IVX]+\.\s+",  # Roman numeral list: I. item
        ]

        return any(re.match(pattern, line) for pattern in list_patterns)

    def _collect_list(self, lines: List[str], start_idx: int) -> Tuple[List[str], int]:
        """
        Collect all lines that are part of an RST list.

        Args:
            lines: All lines in the document
            start_idx: Starting index

        Returns:
            Tuple of (list_lines, next_index)
        """
        list_lines = []
        i = start_idx
        base_indent = self._get_indent_level(lines[start_idx])

        while i < len(lines):
            line = lines[i]

            # If it's a list item at the same or deeper indentation, include it
            if self._is_list_item(line):
                current_indent = self._get_indent_level(line)
                if current_indent >= base_indent:
                    list_lines.append(line)
                    i += 1
                    continue
                else:
                    # List item at shallower indentation, end current list
                    break

            # If it's an empty line, check if the list continues
            if not line.strip():
                # Look ahead to see if list continues
                if i + 1 < len(lines):
                    next_line = lines[i + 1]
                    if (
                        self._is_list_item(next_line)
                        and self._get_indent_level(next_line) >= base_indent
                    ):
                        list_lines.append(line)  # Include the empty line
                        i += 1
                        continue
                    elif (
                        next_line.strip()
                        and self._get_indent_level(next_line) > base_indent
                    ):
                        # Continuation of list item content
                        list_lines.append(line)
                        i += 1
                        continue
                # Empty line and no more list content, end list
                break

            # If it's indented content (continuation of list item), include it
            current_indent = self._get_indent_level(line)
            if line.strip() and current_indent > base_indent:
                list_lines.append(line)
                i += 1
                continue

            # If it's not a list item, not empty, and not indented continuation, end list
            break

        return list_lines, i

    def _is_table_line(self, line: str) -> bool:
        """Check if line is part of an RST table."""
        stripped = line.strip()
        if not stripped:
            return False

        # Grid table patterns
        # Lines made of =, -, +, and spaces (table borders)
        if re.match(r"^[=\-+\s]+$", stripped) and len(stripped) > 3:
            return True

        # Simple table patterns (lines with multiple spaces that could be column separators)
        # But be more conservative - look for patterns that are clearly tabular
        if "   " in stripped and not stripped.startswith(".."):
            # Check if it looks like a table row (has multiple column-like segments)
            segments = [s.strip() for s in stripped.split("   ") if s.strip()]
            if len(segments) >= 2:
                return True

        return False

    def _collect_table(self, lines: List[str], start_idx: int) -> Tuple[List[str], int]:
        """
        Collect all lines that are part of an RST table.

        Args:
            lines: All lines in the document
            start_idx: Starting index

        Returns:
            Tuple of (table_lines, next_index)
        """
        table_lines = []
        i = start_idx

        # Collect all consecutive table-related lines
        while i < len(lines):
            line = lines[i]

            # If it's a table line, include it
            if self._is_table_line(line):
                table_lines.append(line)
                i += 1
                continue

            # If it's an empty line, check if the next line is also a table line
            if not line.strip():
                # Look ahead to see if table continues
                if i + 1 < len(lines) and self._is_table_line(lines[i + 1]):
                    table_lines.append(line)  # Include the empty line
                    i += 1
                    continue
                else:
                    # Empty line and no more table content, end table
                    break

            # If it's not a table line and not empty, end table
            break

        return table_lines, i

    def _is_rst_directive_start(self, line: str) -> bool:
        """Check if line starts an RST directive that has indented content."""
        # Match any RST directive pattern (allowing hyphens in directive names)
        return bool(re.match(r"^\s*\.\.\s+[\w-]+::", line))

    def _is_directive_block_end(self, line: str, directive_indent: int) -> bool:
        """Check if directive block ends."""
        if not line.strip():
            return False
        current_indent = self._get_indent_level(line)
        return current_indent <= directive_indent

    def _get_indent_level(self, line: str) -> int:
        """Get the indentation level of a line."""
        return len(line) - len(line.lstrip())

    def _collect_paragraph(
        self, lines: List[str], start_idx: int
    ) -> Tuple[List[str], int]:
        """
        Collect lines that form a paragraph.

        Args:
            lines: All lines in the document
            start_idx: Starting index

        Returns:
            Tuple of (paragraph_lines, next_index)
        """
        if start_idx >= len(lines):
            return [], start_idx

        current_line = lines[start_idx]

        # Handle special lines
        if self._is_special_line(current_line) or not current_line.strip():
            return [current_line], start_idx + 1

        # Collect continuation lines
        paragraph_lines = [current_line]
        base_indent = self._get_indent_level(current_line)

        i = start_idx + 1
        while i < len(lines):
            line = lines[i]

            # Stop conditions
            if (
                not line.strip()
                or self._is_special_line(line)
                or self._is_table_line(line)  # Stop at table lines
                or self._is_list_item(line)  # Stop at list items
                or abs(self._get_indent_level(line) - base_indent) > 2
            ):
                break

            paragraph_lines.append(line)
            i += 1

        return paragraph_lines, i

    def _is_special_line(self, line: str) -> bool:
        """Check if a line is a special RST construct."""
        stripped = line.strip()

        patterns = [
            r"^\.\.",  # RST directives
            r'^[=\-~^"#*+<>]{3,}$',  # RST headers
            r"^:",  # RST fields
            r"^\s*\.\.\s+_",  # RST targets
        ]

        return any(re.match(pattern, line) for pattern in patterns)

    def _process_paragraph(self, paragraph_lines: List[str]) -> List[str]:
        """
        Process a paragraph by joining and splitting sentences.

        Args:
            paragraph_lines: Lines that form a paragraph

        Returns:
            Processed lines with proper sentence formatting
        """
        if not paragraph_lines or len(paragraph_lines) == 1:
            return paragraph_lines

        if all(self._is_special_line(line) for line in paragraph_lines):
            return paragraph_lines

        # Join all lines
        joined_text = self._join_paragraph_lines(paragraph_lines)

        if not joined_text:
            return paragraph_lines

        # Split into sentences
        sentences = self._split_into_sentences(joined_text)

        # Return sentences with no leading whitespace
        if len(sentences) > 1:
            return [sentence for sentence in sentences if sentence.strip()]
        else:
            return [joined_text]

    def _join_paragraph_lines(self, lines: List[str]) -> str:
        """Join paragraph lines into a single text block."""
        joined_text = ""
        for line in lines:
            text = line.strip()
            if text:
                if joined_text and not joined_text.endswith(" "):
                    joined_text += " "
                joined_text += text
        return joined_text

    def _split_into_sentences(self, text: str) -> List[str]:
        """Split text into sentences at sentence boundaries."""
        # Pattern for sentence endings
        sentence_pattern = r"([.!?]+)(\s+)(?=[A-Z]|\s*$)"
        parts = re.split(sentence_pattern, text)

        if len(parts) <= 1:
            return [text]

        sentences = []
        current_sentence = ""

        i = 0
        while i < len(parts):
            if i + 2 < len(parts) and re.match(r"[.!?]+", parts[i + 1]):
                current_sentence += parts[i] + parts[i + 1]
                sentences.append(current_sentence.strip())
                current_sentence = ""
                i += 3
            else:
                current_sentence += parts[i]
                i += 1

        if current_sentence.strip():
            sentences.append(current_sentence.strip())

        return [s for s in sentences if s.strip()]


def is_rst_file(file_path: Path) -> bool:
    """
    Check if a file is a reStructuredText file.

    Args:
        file_path: Path to check

    Returns:
        True if file appears to be RST, False otherwise
    """
    # Check file extension first
    rst_extensions = {".rst", ".rest", ".restx", ".rtxt"}
    if file_path.suffix.lower() in rst_extensions:
        return True

    # For files without RST extensions, check content
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            # Read first few lines to check for RST patterns
            lines = []
            for _ in range(20):  # Check first 20 lines
                try:
                    line = next(f)
                    lines.append(line)
                except StopIteration:
                    break

        content = "".join(lines)

        # Look for common RST patterns
        rst_patterns = [
            r"^\.\. ",  # RST directives
            r'^[=\-~^"#*+<>]{3,}$',  # RST headers/underlines
            r"^\.\. _",  # RST targets
            r"^\.\. \|",  # RST substitutions
            r"::\s*$",  # RST literal blocks
            r"^\.\. code-block::",  # Code blocks
            r"^\.\. literalinclude::",  # Literal includes
            r"^\.\. note::",  # Admonitions
            r"^\.\. warning::",  # Admonitions
            r"^\.\. image::",  # Images
            r"^\.\. figure::",  # Figures
        ]

        # Count RST-specific patterns
        rst_indicators = 0
        for line in lines:
            line = line.strip()
            for pattern in rst_patterns:
                if re.match(pattern, line, re.MULTILINE):
                    rst_indicators += 1
                    break

        # If we found multiple RST indicators, consider it an RST file
        return rst_indicators >= 2

    except (UnicodeDecodeError, IOError):
        return False


def filter_rst_files(file_paths: List[Path]) -> Tuple[List[Path], List[Path]]:
    """
    Filter files to only include RST files.

    Args:
        file_paths: List of file paths to filter

    Returns:
        Tuple of (rst_files, skipped_files)
    """
    rst_files = []
    skipped_files = []

    for file_path in file_paths:
        if not file_path.exists():
            print(
                f"error: cannot read {file_path}: No such file or directory",
                file=sys.stderr,
            )
            continue

        if not file_path.is_file():
            print(f"error: cannot read {file_path}: Not a file", file=sys.stderr)
            continue

        if is_rst_file(file_path):
            rst_files.append(file_path)
        else:
            skipped_files.append(file_path)

    return rst_files, skipped_files


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Reformat RST files by ensuring each sentence is on its own line",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s file1.rst file2.rst file3.rst
  %(prog)s *.rst
  %(prog)s docs/*.rst
  %(prog)s docs/  # Will find all RST files in directory
        """,
    )

    parser.add_argument(
        "files", nargs="+", type=Path, help="RST files or directories to process"
    )

    parser.add_argument(
        "--check",
        action="store_true",
        help="Don't write the files back, just return the status. "
        "Return code 0 means nothing would change. "
        "Return code 1 means some files would be reformatted.",
    )

    parser.add_argument(
        "--verbose", action="store_true", help="Show files that are skipped"
    )

    parser.add_argument("--version", action="version", version="%(prog)s 1.0.0")

    args = parser.parse_args()

    # Expand directories to find RST files
    all_files = []
    for path in args.files:
        if path.is_dir():
            # Find all potential RST files in directory
            for ext in [".rst", ".rest", ".restx", ".rtxt"]:
                all_files.extend(path.glob(f"**/*{ext}"))
            # Also check files without extensions that might be RST
            for file_path in path.rglob("*"):
                if file_path.is_file() and not file_path.suffix:
                    all_files.append(file_path)
        else:
            all_files.append(path)

    # Filter to only RST files
    rst_files, skipped_files = filter_rst_files(all_files)

    # Show skipped files if verbose
    if args.verbose and skipped_files:
        for file_path in skipped_files:
            print(f"skipped: {file_path} (not a reStructuredText file)")

    if not rst_files:
        if skipped_files:
            print("No reStructuredText files found to format")
        return 0

    # Process RST files
    processor = RSTProcessor()
    changed_files = []
    unchanged_files = []
    error_files = []

    for file_path in rst_files:
        try:
            # Read the original file
            content = processor._read_file(file_path)
            if content is None:
                error_files.append(file_path)
                continue

            # Process the content
            processed_content = processor._process_rst_content(content)

            # Check if content changed
            if content == processed_content:
                unchanged_files.append(file_path)
            else:
                changed_files.append(file_path)
                if not args.check:
                    # Write back to the same file
                    if not processor._write_file(file_path, processed_content):
                        error_files.append(file_path)
                        changed_files.remove(file_path)

        except Exception as e:
            print(f"error: cannot format {file_path}: {e}", file=sys.stderr)
            error_files.append(file_path)

    # Report results in black style
    total_files = len(rst_files)

    if args.check:
        if changed_files:
            print(
                f"would reformat {len(changed_files)} file{'s' if len(changed_files) != 1 else ''}"
            )
            for file_path in changed_files:
                print(f"would reformat {file_path}")
            return 1
        else:
            if total_files == 1:
                print(f"{total_files} file left unchanged")
            else:
                print(f"{total_files} files left unchanged")
            return 0
    else:
        # Normal mode output
        if changed_files:
            for file_path in changed_files:
                print(f"reformatted {file_path}")

        if unchanged_files and not changed_files:
            # Only show "left unchanged" if no files were changed
            if len(unchanged_files) == 1:
                print(f"{len(unchanged_files)} file left unchanged")
            else:
                print(f"{len(unchanged_files)} files left unchanged")
        elif unchanged_files and changed_files:
            # Show summary when both changed and unchanged files exist
            changed_count = len(changed_files)
            unchanged_count = len(unchanged_files)

            parts = []
            if changed_count:
                parts.append(
                    f"{changed_count} file{'s' if changed_count != 1 else ''} reformatted"
                )
            if unchanged_count:
                parts.append(
                    f"{unchanged_count} file{'s' if unchanged_count != 1 else ''} left unchanged"
                )

            print(", ".join(parts))

        return 1 if error_files else 0


if __name__ == "__main__":
    sys.exit(main())
