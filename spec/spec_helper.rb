require 'bundler/setup'
Bundler.setup(:default, :development)

require File.expand_path(File.dirname(__FILE__) + '/../lib/sequel/plugins/paranoid.rb')

RSpec.configure do |config|
  DB = Sequel.sqlite

  DB.create_table(:spec_models) do
    primary_key :id, :auto_increment => true
    DateTime :deleted_at
    String   :name
  end

  DB.create_table(:spec_model_with_default_scopes) do
    primary_key :id, :auto_increment => true
    DateTime :deleted_at
    String   :name
  end

  DB.create_table(:spec_fragments) do
    primary_key :id, :auto_increment => true
    Integer  :spec_model_id
    DateTime :deleted_at
    String   :name
  end

  DB.create_table(:spec_model_with_deleted_bies) do
    primary_key :id, :auto_increment => true
    DateTime :deleted_at
    String   :deleted_by
    String :name
  end

  DB.create_table(:spec_model_with_validation_helpers) do
    primary_key :id, :auto_increment => true
    DateTime :deleted_at
    String   :name
  end
end

class SpecModel < Sequel::Model
  plugin :paranoid, soft_delete_on_destroy: true
  one_to_many :spec_fragments

  attr_accessor :before_destroy_value, :after_destroy_value

  def before_destroy
    @before_destroy_value = true
  end

  def after_destroy
    @after_destroy_value = true
  end
end

class SpecFragment < Sequel::Model
  plugin :paranoid, soft_delete_on_destroy: true
  many_to_one :spec_model
end

class SpecModelWithDefaultScope < Sequel::Model
  plugin :paranoid, soft_delete_on_destroy: true, :enable_default_scope => true
end

class SpecModelWithDeletedBy < Sequel::Model
  plugin :paranoid, soft_delete_on_destroy: true, :enable_deleted_by => true
end

class SpecModelWithCascadeDelete < SpecModel
  plugin :paranoid, soft_delete_on_destroy: true
  one_to_many :spec_fragment

  def before_destroy
    spec_fragments.each { |m| m.destroy }

    super
  end
end

class SpecModelWithValidationHelper < Sequel::Model
  plugin :paranoid, soft_delete_on_destroy: true, include_validation_helpers: true

  module NonParanoidValidation
    def validate
      super
      validates_unique :name
    end
  end

  module ParanoidValidation
    def validate
      super
      validates_unique :name, paranoid: true
    end
  end
end

class SpecModelWithoutDestroyOverwrite < Sequel::Model(:spec_models)

  plugin :paranoid
end
