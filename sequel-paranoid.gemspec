Gem::Specification.new do |s|
  s.name        = 'sequel-paranoid'
  s.version     = '0.4.2'
  s.date        = '2014-04-10'
  s.summary     = "A plugin for the Ruby ORM Sequel, that allows soft deletion of database entries."
  s.description = "Use this plugin to mark a model instance as deleted without loosing its actual data."
  s.authors     = ["Sascha Depold"]
  s.email       = 'sascha.depold@blacklane.com'
  s.files       = ["lib/sequel/plugins/paranoid.rb"]
  s.homepage    = 'https://github.com/blacklane/sequel-paranoid'
  s.license     = "MIT"

  s.add_runtime_dependency "sequel"
end
