## [Unreleased]

## [0.5.0] - 2022-04-19

- Add some static comments to the schema file to improve general Rails intellisense
- Rename schema file from `app/models/annotate_solargraph_schema.rb` to `.annotate-solargraph-schema`
- Generate schema file as a regular ruby file
- Add `yard` and `solargraph` as dependencies
- Add `.solargraph.yml` to the installation generator

## [0.4.0] - 2022-04-17

- Annotations get saved to a schema file by default `app/models/annotate_solargraph_schema.rb`

## [0.3.0] - 2022-04-17

- `has_many :through` and `has_one :through` relations get documented

## [0.2.3] - 2022-04-16

- A nicer fix for the previous problem

## [0.2.2] - 2022-04-16

- Inexistent class loading error has been resolved

## [0.2.1] - 2022-04-16

- Rakefile template refactoring and bug fix

## [0.2.0] - 2022-04-16

- Associations get fully documented
- `has_many`, `has_one` and `belongs_to` relations get documented

## [0.1.1] - 2022-04-15

- Minor bug fix after the initial release

## [0.1.0] - 2022-04-15

- Initial release
- Automatic generation of annotations after migrations
- Database fields get documented
- Manual rake tasks `annotate:solargraph:generate`, `annotate:solargraph:remove`
