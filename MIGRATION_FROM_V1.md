# Migration Guide: v1.x to v2.0

This guide will help you migrate from LazyNames v1.x (YAML configuration) to v2.0 (Ruby configuration).

## Overview

LazyNames v2.0 removes YAML support in favor of plain Ruby configuration files. This change makes the gem more intuitive and Ruby-native.

## Why the Change?

As discussed in the original issue, `.irbrc` and `.pryrc` already support plain Ruby. The YAML abstraction was unnecessary when you can simply write:

```ruby
MUCC = Models::Users::CreditCard
```

Instead of:

```yaml
---
definitions:
  'Models::Users::CreditCard': 'MUCC'
```

## Breaking Changes

- ❌ `.lazy_names.yml` is no longer supported
- ✅ You must use `.lazy_names.rb` instead
- ✅ Constants are validated at load time (mandatory)

## Quick Conversion

### Before (v1.x)

**.lazy_names.yml**:
```yaml
---
definitions:
  'Models::User': 'MU'
  'Services::EmailSender': 'SES'
  'Controllers::API::V1::UsersController': 'CAVUC'
```

### After (v2.0)

**.lazy_names.rb**:
```ruby
MU = Models::User
SES = Services::EmailSender
CAVUC = Controllers::API::V1::UsersController
```

## Automated Conversion Script

Save this as `convert_to_v2.rb` and run it in your project directory:

```ruby
#!/usr/bin/env ruby
require 'yaml'

yaml = YAML.load_file('.lazy_names.yml')
definitions = yaml['definitions'] || yaml.values.first['definitions']

File.open('.lazy_names.rb', 'w') do |f|
  f.puts "# Converted from .lazy_names.yml"
  definitions.each do |full, short|
    f.puts "#{short} = #{full}"
  end
end

puts "✓ Converted to .lazy_names.rb"
```

### Using the Conversion Script

1. Run the script in your project directory:
   ```bash
   ruby convert_to_v2.rb
   ```

2. Review the generated `.lazy_names.rb`:
   ```bash
   cat .lazy_names.rb
   ```

3. Test it in your console:
   ```bash
   bundle exec rails c
   # or
   bin/console
   ```

4. Once verified, delete the old YAML file:
   ```bash
   rm .lazy_names.yml
   ```

## Global Configuration Migration

If you have a global configuration in `~/.lazy_names.yml`:

### Before

**~/.lazy_names.yml**:
```yaml
---
my_project:
  definitions:
    'Models::User': 'MU'
another_project:
  definitions:
    'API::Client': 'AC'
```

### After

You have two options:

**Option 1**: Combine into one file (simpler)

**~/.lazy_names.rb**:
```ruby
# Definitions that work across projects
MU = Models::User if defined?(Models::User)
AC = API::Client if defined?(API::Client)
```

**Option 2**: Use project-specific files

Create `.lazy_names.rb` in each project directory instead of using a global file.

## New Features in v2.0

### Validation

All constants are now validated before being defined:

```ruby
# Valid - will be defined
MU = Models::User

# Invalid - will show warning and skip
INVALID = NonExistent::Class
# Warning: Line 4: Constant NonExistent::Class not found - INVALID = NonExistent::Class
```

### Comments and Formatting

```ruby
# You can add comments to document your shortcuts
MU = Models::User

# Blank lines are allowed for organization

SES = Services::EmailSender

# Underscores and numbers work too
API_V1 = API::V1
CACHE2 = Cache::RedisCache
```

### Better Error Messages

v2.0 provides detailed error messages with line numbers:

```
Loading definitions from /path/to/.lazy_names.rb
Line 5: Constant Foo::Bar not found - FB = Foo::Bar
Loaded 10 definitions
Skipped 1 invalid lines
```

## Troubleshooting

### "Constant not found" warnings

If you see warnings about constants not being found:

1. **Make sure the constant exists** in your application
2. **Check the spelling** - constant names are case-sensitive
3. **Ensure the constant is loaded** before LazyNames runs

Example:
```ruby
# This will fail if Models isn't loaded yet
MU = Models::User

# This is safer - only define if it exists
MU = Models::User if defined?(Models::User)
```

### Constants not defined in console

If constants aren't showing up in your console:

1. Check that `.lazy_names.rb` is in the right location:
   - Project root: `./.lazy_names.rb`
   - Home directory: `~/.lazy_names.rb`

2. Verify your IRB/Pry configuration is correct:

   **For Pry** (`~/.pryrc` or `.pryrc`):
   ```ruby
   if defined?(LazyNames)
     Pry.config.hooks.add_hook(:when_started, :lazy_names) do
       LazyNames.load_definitions!
     end
   end
   ```

   **For IRB** (`~/.irbrc` or `.irbrc`):
   ```ruby
   if defined?(LazyNames)
     LazyNames.load_definitions!
   end
   ```

3. Make sure you've updated to v2.0:
   ```bash
   bundle update lazy_names
   ```

### Migration script errors

If the conversion script fails:

**Error: No .lazy_names.yml found**
- Make sure you're in the correct directory
- Check if the file is named exactly `.lazy_names.yml`

**Error: .lazy_names.rb already exists**
- Review the existing file
- Delete it if you want to regenerate: `rm .lazy_names.rb`
- Or merge manually

## Need Help?

If you encounter issues during migration:

1. Check the [README](README.md) for configuration examples
2. Review the [implementation plan](MIGRATION_PLAN_V2.md) for technical details
3. Open an issue on [GitHub](https://github.com/zhisme/lazy_names/issues)

## Benefits of v2.0

After migrating, you'll enjoy:

- ✅ **More intuitive** - Same syntax as `.irbrc`/`.pryrc`
- ✅ **Better IDE support** - Syntax highlighting and autocomplete
- ✅ **Mandatory validation** - Know immediately if a constant doesn't exist
- ✅ **Simpler** - No YAML parsing overhead
- ✅ **Ruby-native** - Write Ruby to configure Ruby
