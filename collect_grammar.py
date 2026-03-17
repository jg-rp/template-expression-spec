import re

RE_PEG_BLOCK = re.compile(r"```\s?peg([^`]+)```", re.MULTILINE)

with open("spec.md") as fd:
    markdown = fd.read()

blocks = RE_PEG_BLOCK.findall(markdown)

print("".join(blocks))
