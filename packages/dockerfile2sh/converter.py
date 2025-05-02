"""Dockerfile to shell script converter."""

import json
from pathlib import Path
from typing import List, Dict


class DockerfileConverter:
    """Convert Dockerfile instructions to shell script commands."""

    def __init__(self):
        self.env_vars: Dict[str, str] = {}
        self.workdir = "/"
        self.shell_commands: List[str] = []

    def parse_dockerfile(self, content: str) -> None:
        """Parse Dockerfile content and convert to shell commands."""
        # 基本的なシェルスクリプトヘッダーを追加
        self.shell_commands = ["#!/bin/bash", "set -e", ""]

        # 行ごとに処理
        lines = content.splitlines()
        current_instruction = ""

        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            # バックスラッシュで続く行を連結
            if line.endswith("\\"):
                current_instruction += line[:-1] + " "
                continue

            current_instruction += line
            self._convert_instruction(current_instruction)
            current_instruction = ""

    def _convert_instruction(self, instruction: str) -> None:
        """Convert a single Dockerfile instruction to shell command(s)."""
        parts = instruction.split()
        if not parts:
            return

        cmd = parts[0].upper()
        args = " ".join(parts[1:])

        if hasattr(self, f"_handle_{cmd.lower()}"):
            handler = getattr(self, f"_handle_{cmd.lower()}")
            handler(args)

    def _handle_from(self, args: str) -> None:
        """Handle FROM instruction."""
        self.shell_commands.append(f"# Base image would be: {args}")
        self.shell_commands.append("")

    def _handle_run(self, args: str) -> None:
        """Handle RUN instruction."""
        # JSON配列形式のRUN命令を処理
        if args.startswith("["):
            try:
                cmd_parts = json.loads(args)
                args = " ".join(str(part) for part in cmd_parts)
            except json.JSONDecodeError:
                pass

        self.shell_commands.append(args)
        self.shell_commands.append("")

    def _handle_env(self, args: str) -> None:
        """Handle ENV instruction."""
        if "=" in args:
            # ENV KEY=VALUE 形式
            key, value = args.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
        else:
            # ENV KEY VALUE 形式
            parts = args.split()
            key, value = parts[0], " ".join(parts[1:]).strip('"').strip("'")

        self.env_vars[key] = value
        self.shell_commands.append(f'export {key}="{value}"')
        self.shell_commands.append("")

    def _handle_copy(self, args: str) -> None:
        """Handle COPY instruction."""
        parts = args.split()
        dest = parts[-1]
        sources = parts[:-1]

        for src in sources:
            if src.startswith("--from="):
                continue
            src = src.strip('"').strip("'")
            dest = dest.strip('"').strip("'")

            if dest.endswith("/"):
                dest = f"{dest}{Path(src).name}"

            self.shell_commands.append(f'mkdir -p "$(dirname "{dest}")"')
            self.shell_commands.append(f'cp -r "{src}" "{dest}"')
        self.shell_commands.append("")

    def _handle_workdir(self, args: str) -> None:
        """Handle WORKDIR instruction."""
        self.workdir = args.strip('"').strip("'")
        self.shell_commands.append(f'mkdir -p "{self.workdir}"')
        self.shell_commands.append(f'cd "{self.workdir}"')
        self.shell_commands.append("")

    def _parse_json_array(self, json_str: str) -> List[str]:
        """Parse JSON array format and return command parts."""
        try:
            parts = json.loads(json_str)
            if isinstance(parts, list):
                return [str(part) for part in parts]
        except json.JSONDecodeError:
            pass
        return []

    def _handle_cmd(self, args: str) -> None:
        """Handle CMD instruction."""
        cmd = ""
        if args.startswith("[") and args.endswith("]"):
            parts = self._parse_json_array(args)
            if parts:
                cmd = " ".join(parts)
        else:
            cmd = args.strip('"').strip("'")

        if cmd:
            self.shell_commands.append(f"# Default command: {cmd}")
            self.shell_commands.append(f"exec {cmd}")
        self.shell_commands.append("")

    def _handle_arg(self, args: str) -> None:
        """Handle ARG instruction."""
        if "=" in args:
            # ARG name=value 形式
            name, value = args.split("=", 1)
            name = name.strip()
            value = value.strip().strip('"').strip("'")
            self.shell_commands.append(f'{name}="{value}"')
        else:
            # ARG name 形式
            name = args.strip()
            self.shell_commands.append(f'{name}=""')
        self.shell_commands.append("")

    def get_shell_script(self) -> str:
        """Get the generated shell script content."""
        return "\n".join(self.shell_commands)


def convert_dockerfile(dockerfile_content: str) -> str:
    """Convert Dockerfile content to shell script."""
    converter = DockerfileConverter()
    converter.parse_dockerfile(dockerfile_content)
    return converter.get_shell_script()
