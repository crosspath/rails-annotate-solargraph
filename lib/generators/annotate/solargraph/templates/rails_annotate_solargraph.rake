# frozen_string_literal: true

if ::Rails.env.development?
  namespace :annotate do
    desc "Add YARD comments documenting the models' schemas"
    task solargraph: :environment do
      system 'rails runner "p ::Rails::Annotate::Solargraph.generate"'
    end

    desc "Remove YARD comments documenting the models' schemas"
    task remove_solargraph: :environment do
      system 'rails runner "p ::Rails::Annotate::Solargraph.remove"'
    end
  end
end
