import argparse
from pathlib import Path
import sys

IGNORE_DIRS = {
    "AppData",
    "Application Data",
    "Local Settings",
    "$RECYCLE.BIN",
    ".git",
}


def search_files(
    directory: str,
    substring: str,
    extensions: tuple[str, ...],
    ignore_case: bool,
) -> None:
  folder = Path(directory)
  current_script = Path(__file__).resolve()

  if not folder.is_dir():
    print(f"[ОШИБКА] Директория '{directory}' не найдена.")
    return

  target = substring.lower() if ignore_case else substring
  matches_count = 0

  print(f"Поиск '{substring}' в '{folder.resolve()}'...")
  print("Нажмите Ctrl+C для принудительной остановки.\n" + "=" * 40)

  for file_path in folder.rglob("*"):
    if any(part in IGNORE_DIRS for part in file_path.parts):
      continue

    try:
      if not file_path.is_file():
        continue

      full_path = file_path.resolve()
      if full_path == current_script:
        continue

      if extensions and file_path.suffix.lower() not in extensions:
        continue

      with file_path.open(mode="r", encoding="utf-8") as file:
        for line_number, line in enumerate(file, start=1):
          check_line = line.lower() if ignore_case else line

          if target in check_line:
            matches_count += 1
            print(f"Файл: {full_path}")
            print(f"Строка {line_number}: {line.strip()}")
            print("-" * 40)

    except (UnicodeDecodeError, PermissionError, OSError):
      continue

  print(f"\nПоиск завершен. Найдено совпадений: {matches_count}")


def main() -> None:
  parser = argparse.ArgumentParser(
      description="Консольная утилита для поиска текста в файлах."
  )
  parser.add_argument("text", help="Текст или подстрока для поиска")
  parser.add_argument(
      "-d",
      "--dir",
      default=".",
      help="Путь к папке для поиска (по умолчанию текущая)",
  )
  parser.add_argument(
      "-e",
      "--ext",
      nargs="*",
      default=[],
      help="Расширения файлов через пробел (например: .txt .log)",
  )
  parser.add_argument(
      "-i",
      "--ignore-case",
      action="store_true",
      help="Игнорировать регистр букв",
  )

  args = parser.parse_args()
  extensions = tuple(
      ext.lower() if ext.startswith(".") else f".{ext.lower()}"
      for ext in args.ext
  )

  try:
    search_files(args.dir, args.text, extensions, args.ignore_case)
  except KeyboardInterrupt:
    print("\n\n[ОСТАНОВЛЕНО] Поиск прерван пользователем (Ctrl+C).")
    sys.exit(0)


if __name__ == "__main__":
  main()
