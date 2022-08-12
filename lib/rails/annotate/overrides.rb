# frozen_string_literal: true

require 'parser/current'

class ActiveRecord::Base
  class << self
    alias orig_scope scope

    def scope(*args, **kwargs, &block)
      file_path, scope_line_number = caller.first.split(':')
      scope_line_number = scope_line_number.to_i
      scope_name = args.first
      scope_proc = args[1]
      proc_parameters = scope_proc.respond_to?(:parameters) ? scope_proc.parameters.map(&:last) : []
      scope_definition = ::String.new
      scope_model_class = self
      scope_lines = 0
      scope_indentation = nil

      ::File.open(file_path) do |file|
        file.each_line.with_index(1) do |line, current_line_number|
          next if current_line_number < scope_line_number
          break if scope_lines > 50

          scope_indentation ||= line.length - line.lstrip.length
          scope_definition << "#{line.rstrip[scope_indentation..]}\n"
          scope_lines += 1

          break if ::Parser::CurrentRuby.new.parse ::Parser::Source::Buffer.new('(string)', source: scope_definition)
        end
      end

      ::Rails::Annotate::Solargraph::Model.add_scope(scope_name.to_sym, scope_model_class, proc_parameters, scope_definition)

      orig_scope(*args, **kwargs, &block)
    rescue ::StandardError
      orig_scope(*args, **kwargs, &block)
    end
  end
end
