module Config
  def self.configure_annotate_solargraph
    ::Rails::Annotate::Solargraph.configure do |conf|
      conf.annotation_position = ::ENV['SCHEMA_FILE'] ? :schema_file : :bottom
    end
  end
end

::Config.configure_annotate_solargraph if ::Rails.env.development?
