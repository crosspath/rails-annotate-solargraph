# frozen_string_literal: true

module Rails
  module Annotate
    module Solargraph
      module TerminalColors
        extend self

        # @return [Hash{Symbol => String}]
        MAP = {
          blue: (BLUE = "\033[94m"),
          cyan: (CYAN = "\033[96m"),
          green: (GREEN = "\033[92m"),
          yellow: (YELLOW = "\033[93m"),
          red: (RED = "\033[91m"),
          terminate: (TERMINATE = "\033[0m"),
          bold: (BOLD = "\033[1m"),
          italic: (ITALIC = "\033[3m"),
          underline: (UNDERLINE = "\033[4m")
        }.freeze

        class << self
          # Style a string with an ASCII escape code
          #
          # @param string [String]
          # @param style [Symbol]
          # @return [String]
          def with_style(string, style)
            "#{MAP[style]}#{string}#{TERMINATE}"
          end

          # Style a string with multiple ASCII escape codes
          #
          # @param string [String]
          # @param styles [Array<Symbol>]
          # @return [String]
          def with_styles(string, *styles)
            result = ::String.new
            styles.each do |style|
              result << MAP[style]
            end

            result << "#{string}#{TERMINATE}"
          end
        end

        def title_string(string)
          TerminalColors.with_styles "== #{string} ==", :cyan, :underline, :italic
        end

        def error_string(string)
          TerminalColors.with_styles "!! #{string} !!", :bold, :red
        end

        def title(string)
          puts "\n", title_string(string)
        end

        def error(string)
          puts "\n", error_string(string)
        end

        module Refinement
          refine ::String do
            # @param styles [Array<Symbol]>
            # @return [self] Colored string
            def with_styles(*styles)
              ::Rails::Annotate::Solargraph::TerminalColors.with_styles(self, *styles)
            end
          end
        end

      end
    end
  end
end
