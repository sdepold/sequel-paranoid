require 'sequel'

module Sequel::Plugins
  module Paranoid
    def self.configure(model, options = {})
      model.instance_eval do

        #
        # Inject the scopes for the deleted and the existing entries.
        #

        dataset_module do
          def deleted
            unfiltered.exclude(:deleted_at => nil)
          end

          def existing
            unfiltered.filter(:deleted_at => nil)
          end
        end

        #
        # Shortcut method to return the unfiltered dataset.
        #

        def unfiltered
          dataset.unfiltered
        end

        #
        # Overwrite the "destroy" method.
        #

        define_method("destroy") do
          self.before_destroy if self.respond_to?(:before_destroy)

          self.deleted_at = Time.now

          if save and self.respond_to?(:after_destroy)
            self.after_destroy
          end
        end


        #
        # Inject the default scope that filters deleted entries.
        #

        set_dataset(self.existing)
      end
    end
  end
end
