#!/usr/bin/env python

"""Main entry point for dockerfile2sh."""

import sys
import os

if __name__ == "__main__":
    try:
        # パッケージとして実行する場合
        from .cli import main
    except ImportError:
        # スクリプトとして直接実行する場合
        # パッケージ内部からインポートするために相対パスを追加
        sys.path.insert(0, os.path.abspath(os.path.dirname(os.path.dirname(__file__))))
        from dockerfile2sh.cli import main

    main()
