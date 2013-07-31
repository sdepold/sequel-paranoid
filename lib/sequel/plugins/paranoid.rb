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
        :set_default_scope          => false
      }.merge(options)

      model.instance_eval do
        #
        # Inject the scopes for the deleted and the existing entries.
        #

        dataset_module do
          # scope for deleted items
          define_method(options[:deleted_scope_name]) do
            send(options[:ignore_deletion_scope_name]).exclude(options[:deleted_at_field_name] => nil)
          end

          # scope for non-deleted items
          define_method(options[:non_deleted_scope_name]) do
            filter(options[:deleted_at_field_name] => nil)
          end

          # scope for both
          define_method(options[:ignore_deletion_scope_name]) do
            unfiltered
          end
        end

        #
        # Overwrite the "destroy" method.
        #

        define_method("destroy") do
          # call the before_destroy hook if present
          if self.respond_to?(:before_destroy)
            self.before_destroy
          end

          # set the deletion time
          self.deleted_at = Time.now

          # save the instance and call the after_destroy hook if present
          if save and self.respond_to?(:after_destroy)
            self.after_destroy
          end
        end

        #
        # Method for undeleting an instance.
        #

        define_method("recover") do
          self.class.send(options[:ignore_deletion_scope_name]).where(:id => self.id).update(options[:deleted_at_field_name] => nil)
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

        if options[:set_default_scope]
          set_dataset(self.send(options[:non_deleted_scope_name]))
        end
      end
    end
  end
end
