require 'active_record'
require 'byebug'
require 'rspec/json_expectations'

connection_info = YAML.load(ERB.new(File.read(__dir__ + '/../config/database.yml')).result)['test']
ActiveRecord::Base.establish_connection(connection_info)

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
