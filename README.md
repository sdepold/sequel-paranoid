# sequel-paranoid

A plugin for the Ruby ORM Sequel, that allows soft deletion of database entries.

## Usage

### Basics

In order to use the paranoid plugin in the very basic version, just add it your model like this:

```rb
class ParanoidModel < Sequel::Model
  plugin :paranoid
end
```

This will assume that you have a column `deleted_at`, which gets filled with the current timestamp once the model gets destroyed:

```rb
instance = ParanoidModel.create(:something)

instance.deleted?    # => false
instance.deleted_at  # => nil

instance.soft_delete # sets the deleted_at column and soft deletes the record. `destroy` still works normally.
record.paranoid_models_dataset.soft_delete # also allows soft deletion in bulk on the dataset.

instance.deleted?    # => true
instance.deleted_at  # => current timestamp
```

### Reading The Data

By default the plugin will not change the way scopes have been working. So if you want to take the deletion state of an entry into account
you can use the following dataset filters:

```rb
ParanoidModel.not_deleted.all  # => Will return all the non-deleted entries from the db.
ParanoidModel.deleted.all      # => Will return all the deleted entries from the db.
ParanoidModel.with_deleted.all # => Will ignore the deletion state (and is the default).
```

### Renaming The Deletion Timestamp Columns

If you don't want to use the default column name `deleted_at`, you can easily rename that column:

```rb
class ParanoidModel < Sequel::Model
  plugin :paranoid, :deleted_at_field_name => :destroyed_at
end

instance = ParanoidModel.create(:something => 'foo')

instance.soft_delete
instance.destroyed_at # => current timestamp
```

### Side Effects Mode (Enable Default Scope & Override `destroy`)

If you want a more "magical" implementation, you will need to opt-in. 


In order to exclude deleted entries by default from any query, you can enable an option in the plugin. We highly advise against these modes because it will not interoperate well with associations when you want to load deleted associated instances.

If you want to override `destroy`, you can opt-in for this with the `soft_delete_on_destroy` option.

```rb
class ParanoidModel < Sequel::Model
  plugin :paranoid, :enable_default_scope => true, :soft_delete_on_destroy => true
  one_to_many :child_models
end

class ChildModel < Sequel::Model
  plugin :paranoid, :soft_delete_on_destroy => true
  many_to_one :paranoid_model
end

# create some dummy data

parent1 = ParanoidModel.create(:something => 'foo')
parent2 = ParanoidModel.create(:something => 'bar')

child1  = ChildModel.create(:something => 'foo')
child2  = ChildModel.create(:something => 'bar')
child3  = ChildModel.create(:something => 'baz')

parent1.add_child_model(child1)
parent1.add_child_model(child2)
parent2.add_child_model(child3)

# destroy one of the children

child1.destroy
child1.deleted? # => true

# load the children

ChildModel.all                              # => [child2, child3] (works as expected)
ChildModel.dataset.unfiltered.all           # => [child1, child2, child3] (works as expected)

parent1.child_models_dataset.all            # => [child2] (works as expected)
parent1.child_models_dataset.unfiltered.all # => [child1, child2, child3] (broken)
```

Note that the last command is broken, as `child3` is not associated with parent1. The reason for that is `unfiltered`,
which will not only remove the `deleted_at` check but also the assocation condition of the query.

### Validates Helpers

You can supply `:include_validation_helpers => true` to enable uniqueness on non-deleted records.

```rb
class ParanoidModel < Sequel::Model
  plugin :paranoid, :include_validation_helpers => true
  
   def validate
     super
     validates_unique :name, :paranoid => true
   end
    
end
```

### Using Unique Constraints With Soft-deletion

You can use the `:deleted_column_default` option in order to specify a value
that is not `NULL`, which will allow you to include the column in a unique
constraint.

Using this option requires you to also set this default column value in your
database.

```rb
class ParanoidModel < Sequel::Model
  plugin :paranoid, :deleted_column_default => Time.at(0)
end
```

## Contributors ##
 * [Aryk](https://github.com/Aryk)
 * [halostatue](https://github.com/halostatue)
 * [iblue](https://github.com/iblue)
 * [drosile](https://github.com/drosile)
 * [lipanski](https://github.com/lipanski)
 * [GarPit](https://github.com/GarPit)
 * [reidmix](https://github.com/reidmix)
