# frozen_string_literal: true

class ActiveRecord::Base
  class << self
    alias orig_scope scope

    def scope(*args, **kwargs, &block)
      file_path, scope_line_number = caller.first.split(':')
      scope_line_number = scope_line_number.to_i
      scope_name = args.first
      scope_proc = args[1]
      proc_parameters = scope_proc.respond_to?(:parameters) ? scope_proc.parameters.map(&:last) : []
      scope_line = nil
      scope_model_class = self

      ::File.open(file_path) do |file|
        file.each_line.with_index(1) do |line, current_line_number|
          next unless current_line_number == scope_line_number

          scope_line = line.strip
          break
        end
      end

      ::Rails::Annotate::Solargraph::Model.add_scope(scope_name.to_sym, scope_model_class, proc_parameters, scope_line)

      orig_scope(*args, **kwargs, &block)
    end
  end
end
