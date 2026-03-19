# frozen_string_literal: true

SPEC_FILES = ARGV

blocks = SPEC_FILES.map { |file| File.read(file).scan(/^```\s*peg([^`]+)```/).first }

# TODO: for each block
#  - split into lines
#  - split at <-
#  - remember the furthest column index of ->

pp(blocks.flatten.first.lines)

arrow_column = blocks.map(&:lines).flat_map { |line| line.index("←") }.compact.max

puts arrow_column

# TODO: for each block
#  - for each line
#   - join rule name and rule back together with new -> alignment
#  - join lines back together

# TODO: join blocks

# # Split rules at first ←
# parsed = rules.map do |r|
#   if r.include?("←")
#     left, right = r.split("←", 2)
#     [left.strip, right.strip]
#   else
#     [r.strip, ""]
#   end
# end

# # Compute alignment width
# max_left = parsed.map { |l, _| l.length }.max || 0

# out = []
# out << "# A. Collected PEG Grammar {.unnumbered}"
# out << ""
# out << "```peg"

# parsed.each do |left, right|
#   padding = " " * (max_left - left.length)
#   out << "#{left}#{padding} ← #{right}".rstrip
#   out << "" # blank line between rules
# end

# out << "```"

# puts out.join("\n")
