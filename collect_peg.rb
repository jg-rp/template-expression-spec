# frozen_string_literal: true

SPEC_FILES = ARGV

blocks = SPEC_FILES.flat_map { |file| File.read(file).scan(/^```\s*peg([^`]+)```/) }.flatten

max_arrow_column = blocks.flatten.flat_map(&:lines).filter_map { |line| line.index("←") }.max

normalized_blocks = blocks.map do |block|
  lines = block.lstrip.lines
  local_col = lines.first.index("←")
  raise "expected the first line to contain a rule" unless local_col

  pad = " " * (max_arrow_column - local_col)
  lines.map { |line| line.insert(line.include?("←") ? local_col : 0, pad) }.join
end

out = []
out << "# Appendix B. Collected PEG Grammar {.unnumbered}"
out << ""
out << "This appendix collects grammar rules used throughout this document."
out << ""
out << "```peg"
out << normalized_blocks.join("\n")
out << "```"

puts out.join("\n")
