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
        :enable_default_scope       => false
      }.merge(options)

      model.instance_eval do
        #
        # Inject the scopes for the deleted and the existing entries.
        #

        dataset_module do
          # scope for deleted items
          define_method(options[:deleted_scope_name]) do
            send(options[:ignore_deletion_scope_name]).exclude(Sequel.qualify(model.table_name, options[:deleted_at_field_name]) => nil)
          end

          # scope for non-deleted items
          define_method(options[:non_deleted_scope_name]) do
            filter(Sequel.qualify(model.table_name, options[:deleted_at_field_name]) => nil)
          end

          # scope for both
          define_method(options[:ignore_deletion_scope_name]) do
            unfiltered
          end
        end

        #
        # Overwrite the "destroy" method.
        #

        define_method("destroy") do |*args|
          destroy_options = args.first

          # call the before_destroy hook if present
          if self.respond_to?(:before_destroy)
            self.before_destroy
          end

          # set the deletion time
          self.send("#{options[:deleted_at_field_name]}=", Time.now)

          # set the deletion author
          if options[:enable_deleted_by] && destroy_options && destroy_options[:deleted_by]
            self.send("#{options[:deleted_by_field_name]}=", destroy_options[:deleted_by])
          end

          # save the instance and call the after_destroy hook if present
          if save and self.respond_to?(:after_destroy)
            self.after_destroy
          end
        end

        #
        # Method for undeleting an instance.
        #

        define_method("recover") do
          self.send("#{options[:deleted_at_field_name]}=".to_sym, nil)

          if options[:enable_deleted_by] && self.respond_to?(options[:deleted_by_field_name].to_sym)
            self.send("#{options[:deleted_by_field_name]}=", nil)
          end

          self.save
        end

        #
        # Check if an instance is deleted.
        #

        define_method("deleted?") do
          !!send(options[:deleted_at_field_name])
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
