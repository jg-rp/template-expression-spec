# frozen_string_literal: true

module Expr
  RE_SLASH_U = /\\u([0-9a-fA-F]{4})/

  def self.unescape(pair)
    unescaped = [] # : Array[String]
    scanner = StringScanner.new(pair.text)

    until scanner.eos?
      if scanner.scan(RE_SLASH_U)
        code_point = (scanner.captures&.first || raise).to_i(16)
        raise "unexpected low surrogate" if low_surrogate?(code_point)

        if high_surrogate?(code_point)
          raise "expected a low surrogate" unless scanner.scan(RE_SLASH_U)

          low_surrogate = (scanner.captures&.first || raise).to_i(16)
          code_point = 0x10000 + (
            ((code_point & 0x03FF) << 10) | (low_surrogate & 0x03FF)
          )
        end

        unescaped << code_point.chr(Encoding::UTF_8)
        next
      end

      ch = scanner.getch

      break if ch.nil?

      unless ch == "\\"
        unescaped << ch
        next
      end

      ch = scanner.getch

      case ch
      when "\""
        unescaped << "\""
      when "'"
        unescaped << "'"
      when "\\"
        unescaped << "\\"
      when "/"
        unescaped << "/"
      when "b"
        unescaped << "\x08"
      when "f"
        unescaped << "\x0c"
      when "n"
        unescaped << "\n"
      when "r"
        unescaped << "\r"
      when "t"
        unescaped << "\t"
      when nil
        raise "incomplete escape sequence"
      else
        raise "unknown escape sequence"
      end
    end

    unescaped.join
  end

  def self.high_surrogate?(code_point)
    code_point.between?(0xD800, 0xDBFF)
  end

  def self.low_surrogate?(code_point)
    code_point.between?(0xDC00, 0xDFFF)
  end
end
