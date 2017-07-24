require 'sequel'

module Sequel::Plugins
  module Paranoid

    def self.configure(model, options = {})
      model.sequel_paranoid_options = options = {
        :deleted_at_field_name      => :deleted_at,
        :deleted_by_field_name      => :deleted_by,
        :delete_method_name         => :soft_delete,
        :enable_deleted_by          => false,
        :deleted_scope_name         => :deleted,
        :non_deleted_scope_name     => :not_deleted,
        :ignore_deletion_scope_name => :with_deleted,
        :enable_default_scope       => false,
        :soft_delete_on_destroy     => false,
        :deleted_column_default     => nil,
        :include_validation_helpers => false,
      }.update(options)

      delete_attributes = proc do |*args|
        destroy_options = args.first || {}

        attrs = {}
        # set the deletion time
        attrs[options[:deleted_at_field_name]] = Time.now

        # set the deletion author
        if options[:enable_deleted_by] && destroy_options && destroy_options[:deleted_by]
          attrs[options[:deleted_by_field_name]] = destroy_options[:deleted_by]
        end

        attrs
      end

      ds_mod = Module.new do
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

        # soft delete the records without callbacks.
        define_method(options[:delete_method_name]) do |*args|
          update(delete_attributes.call(*args))
        end

      end

      im_mod = Module.new do

        define_method(options[:delete_method_name]) do |*args|
          self.set(delete_attributes.call(*args))
          self.save
        end

      end

      model.instance_eval do
        dataset_module ds_mod
        include im_mod

        plugin SoftDeleteOnDestroy if options[:soft_delete_on_destroy]
        plugin EnableDefaultScope if options[:enable_default_scope]
        plugin Validations if options[:include_validation_helpers]
      end
    end

    module ClassMethods
      attr_accessor :sequel_paranoid_options

      ::Sequel::Plugins.inherited_instance_variables(self, :@sequel_paranoid_options=>:hash_dup)
    end

    module InstanceMethods

      #
      # Method for undeleting an instance.
      #
      def recover
        opts = self.class.sequel_paranoid_options
        send("#{opts[:deleted_at_field_name]}=".to_sym, opts[:deleted_column_default])

        if opts[:enable_deleted_by] && self.respond_to?(opts[:deleted_by_field_name].to_sym)
          send("#{opts[:deleted_by_field_name]}=", nil)
        end

        save
      end

      #
      # Check if an instance is deleted.
      #

      def deleted?
        opts = self.class.sequel_paranoid_options
        send(opts[:deleted_at_field_name]) != opts[:deleted_column_default]
      end

    end

    module SoftDeleteOnDestroy
      module InstanceMethods
        def destroy(*args)
          # Save the variables threadsafe (because the locks have not been
          # initialized by sequel yet).
          Thread.current["_paranoid_destroy_args_#{self.object_id}"] = args

          super(*args)
        end

        #
        # Overwrite the "_destroy_delete" method which is used by sequel to
        # delete an object. This makes sure, we run all the hook correctly and
        # in a transaction.
        #

        def _destroy_delete
          # _destroy_delete does not take arguments.
          destroy_options = Thread.current["_paranoid_destroy_args_#{self.object_id}"].first
          Thread.current["_paranoid_destroy_args_#{self.object_id}"] = nil

          send(self.class.sequel_paranoid_options[:delete_method_name], destroy_options)
        end
      end
    end

    module EnableDefaultScope

      def self.configure(model)
        model.class_eval do
          set_dataset(send(sequel_paranoid_options[:non_deleted_scope_name]))
        end
      end

      module InstanceMethods

        #
        # Sequel patch to allow updates to deleted instances
        # when default scope is enabled
        #
        def _update_without_checking(columns)
          # figure out correct pk conditions (see base#this)
          conditions = this.send(:joined_dataset?) ? qualified_pk_hash : pk_hash

          # turn off with deleted, added the pk conditions back in
          update_with_deleted_dataset = this.with_deleted.where(conditions)

          # run the original update on the with_deleted dataset
          update_with_deleted_dataset.update(columns)

        end

      end
    end

    module Validations

      def self.apply(base)
        base.plugin :validation_helpers
      end

      module InstanceMethods
        #
        # Enhance validates_unique to support :paranoid => true for paranoid
        # uniqueness checking.
        #
        def validates_unique(*columns)
          return super(*columns) unless columns.last.kind_of?(Hash) && columns.last.delete(:paranoid)

          opts = self.class.sequel_paranoid_options
          if deleted?
            columns = columns.map { |c|
              case c
              when Array, Symbol
                [ c, opts[:deleted_at_field_name] ].flatten
              else
                c
              end
            }

            super(*columns) { |ds|
              ds = ds.send(opts[:deleted_scope_name])
              block_given? ? yield(ds) : ds
            }
          else
            super(*columns) { |ds|
              ds = ds.send(opts[:non_deleted_scope_name])
              block_given? ? yield(ds) : ds
            }
          end
        end
      end

    end
  end
end
