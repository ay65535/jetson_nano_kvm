"""Command line interface for dockerfile2sh."""

import sys
from pathlib import Path
import click
from .converter import convert_dockerfile


@click.command()
@click.argument(
    "dockerfile", type=click.Path(exists=True, dir_okay=False), required=False
)
@click.option(
    "-o",
    "--output",
    type=click.Path(dir_okay=False),
    help="Output shell script file path",
)
def main(dockerfile: str, output: str):
    """Convert Dockerfile to shell script.

    If DOCKERFILE is not provided, reads from stdin.
    If --output is not provided, writes to stdout.
    """
    try:
        # DockerfileコンテンツをStdinまたはファイルから読み込み
        if dockerfile:
            content = Path(dockerfile).read_text()
        else:
            content = sys.stdin.read()

        # Dockerfileを変換
        shell_script = convert_dockerfile(content)

        # 結果を出力
        if output:
            Path(output).write_text(shell_script)
            click.echo(f"Shell script saved to: {output}", err=True)
        else:
            click.echo(shell_script)

    except Exception as e:
        click.echo(f"Error: {str(e)}", err=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
