## Changelog

### 0.6.2
- Fix handling of default scopes

### 0.6.1
- Fix cascade deletes

### 0.6.0
- Reflect ownership change in gemspec.

### 0.5.0
- Permit changing the default value of the *deleted column* via the `deleted_column_default` option.

### 0.4.3
- Fully qualify the columns.

### 0.4.2
- Fixed rollbacks in transactions.

### 0.4.1
- Set the `deleted_by` field to nil on `.recover`.

### 0.4
- Added possibility to set the author of the deletion.

### 0.3
- Added options.
- Default scope has to be enabled manually.

### 0.2
- Added the method `deleted?`, which returns whether the object is deleted or not.

### 0.1
- Instances can be destroyed + recovered.
