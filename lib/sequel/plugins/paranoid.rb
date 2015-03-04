require 'sequel'

module Sequel::Plugins
  module Paranoid
    def self.configure(model, options = {})
      options = {
        :deleted_at_field_name      => :deleted_at,
        :deleted_by_field_name      => :deleted_by,
        :enable_deleted_by          => false,
        :deleted_scope_name         => :deleted,
        :non_deleted_scope_name     => :present,
        :ignore_deletion_scope_name => :with_deleted,
        :enable_default_scope       => false,
        :deleted_column_default     => nil
      }.merge(options)

      model.instance_eval do
        #
        # Inject the scopes for the deleted and the existing entries.
        #

        dataset_module do
          # scope for deleted items
          define_method(options[:deleted_scope_name]) do
            send(options[:ignore_deletion_scope_name]).exclude(Sequel.qualify(model.table_name, options[:deleted_at_field_name]) => options[:deleted_column_default])
          end

          # scope for non-deleted items
          define_method(options[:non_deleted_scope_name]) do
            filter(Sequel.qualify(model.table_name, options[:deleted_at_field_name]) => options[:deleted_column_default])
          end

          # scope for both
          define_method(options[:ignore_deletion_scope_name]) do
            unfiltered
          end
        end

        #
        # Overwrite the "_destroy_delete" method which is used by sequel to
        # delete an object. This makes sure, we run all the hook correctly and
        # in a transaction.
        #
        define_method("destroy") do |*args|
          # Save the variables threadsafe (because the locks have not been
          # initialized by sequel yet).
          Thread.current[:_paranoid_destroy_args] = args

          super(*args)
        end

        define_method("_destroy_delete") do
          # _destroy_delete does not take arguments.
          destroy_options = Thread.current[:_paranoid_destroy_args].first
          Thread.current[:_paranoid_destroy_args] = nil

          # set the deletion time
          self.send("#{options[:deleted_at_field_name]}=", Time.now)

          # set the deletion author
          if options[:enable_deleted_by] && destroy_options && destroy_options[:deleted_by]
            self.send("#{options[:deleted_by_field_name]}=", destroy_options[:deleted_by])
          end

          self.save
        end

        #
        # Method for undeleting an instance.
        #

        define_method("recover") do
          self.send("#{options[:deleted_at_field_name]}=".to_sym, options[:deleted_column_default])

          if options[:enable_deleted_by] && self.respond_to?(options[:deleted_by_field_name].to_sym)
            self.send("#{options[:deleted_by_field_name]}=", nil)
          end

          self.save
        end

        #
        # Check if an instance is deleted.
        #

        define_method("deleted?") do
          send(options[:deleted_at_field_name]) != options[:deleted_column_default]
        end

        #
        # Inject the default scope that filters deleted entries.
        #

        if options[:enable_default_scope]
          set_dataset(self.send(options[:non_deleted_scope_name]))
        end
      end
    end
  end
end
