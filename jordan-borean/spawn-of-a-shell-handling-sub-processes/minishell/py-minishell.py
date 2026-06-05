#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "psrpcore >= 0.3.0",
# ]
# ///

import sys

import psrpcore


class CustomObject:
    def __init__(self) -> None:
        self.attribute = 'value'
        self.other = 123


def main() -> None:
    shell = psrpcore.ClixmlShell()

    # write_output can write any object
    shell.write_output("string value")
    shell.write_output(CustomObject())

    # write_verbose can write verbose records
    shell.write_verbose("verbose record")

    # When finish, write the CLIXML to stdout
    sys.stdout.write(shell.data_to_send())


if __name__ == '__main__':
    main()
