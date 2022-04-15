# Rails::Annotate::Solargraph

![pipeline status](https://gitlab.com/mateuszdrewniak/rails-annotate-solargraph/badges/main/pipeline.svg)

This gem is inspired by [ctran/annotate_models](https://github.com/ctran/annotate_models).

It automatically generates YARD comments for every model
in your Rails application. They're formatted in a way to make them easy
to parse for [Solargraph](https://solargraph.org/) (a great gem that serves
as a Ruby language server for your IDE).

Here's how you can generate and use these annotations.

![Annotation Generation Gif](assets/annotation_generation_demo.gif)

They're automatically updated and generated when you execute migrations
in the development environment.

![Automatic Annotations Gif](assets/automatic_annotations_demo.gif)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-annotate-solargraph'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rails-annotate-solargraph

Then use this command to generate appropriate Rakefiles

    $ rails g annotate:solargraph:install


And you're ready to go!

Comments should be automatically added and
updated once you execute a migration.

## Usage

You can also manually generate or remove annotations.

### Annotate all models

    $ rake annotate:solargraph:generate

### Remove all annotations

    $ rake annotate:solargraph:remove

### Configure

You can change the gem's default configuration like so:

```ruby
# config/initializers/rails_annotate_solargraph.rb

Rails::Annotate::Solargraph.configure do |conf|
    conf.annotation_position = :top # `:bottom` by default
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on Gitlab at https://gitlab.com/mateuszdrewniak/rails-annotate-solargraph.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
