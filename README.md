[![rake](https://github.com/zhisme/lazy_names/actions/workflows/rake.yml/badge.svg)](https://github.com/zhisme/lazy_names/actions/workflows/rake.yml)
[![Gem Version](https://badge.fury.io/rb/lazy_names.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/lazy_names)
![Gem Total Downloads](https://img.shields.io/gem/dt/lazy_names)
[![Hits-of-Code](https://hitsofcode.com/github/zhisme/lazy_names?branch=master)](https://hitsofcode.com/github/zhisme/lazy_names/view?branch=master)
[![codecov](https://codecov.io/gh/zhisme/lazy_names/graph/badge.svg?token=ZQXGBALJSK)](https://codecov.io/gh/zhisme/lazy_names)
![GitHub License](https://img.shields.io/github/license/zhisme/lazy_names)

# lazy_names

lazy_names helps programmer to type faster very-long class names constants by defining them on a shorter version.
If you are lazy like me typing many times a day in console long constants then this gem will ease your development process.

## Why

Consider this example from pry terminal session.
![Lazy names in action](https://media.giphy.com/media/7CtRJfp2yocsOu9zEA/source.gif)

The idea is to reduce typing of long namespaced constants to shorter versions. It's very useful when you have a lot of nested namespaces and you need to access them frequently. This gem will take your responsibility to redefine constants to shorter versions and making constant/classes validations.

## Why Plain Ruby? (v2.0+)

LazyNames v2.0 uses plain Ruby instead of YAML because:

- ✅ **Intuitive**: Same syntax you'd write in `.irbrc`/`.pryrc`
- ✅ **IDE Support**: Syntax highlighting and autocomplete work out of the box
- ✅ **Validation**: Constants are validated at load time
- ✅ **Simpler**: No YAML parsing, no extra abstraction
- ✅ **Ruby-native**: Write Ruby to configure Ruby

## Installation

1. Add this line to your application's Gemfile:

```ruby
group :development do
  gem 'lazy_names'
end
```
2. Setup your console to automatically load lazy names

- If you are using pry, add this line to `~/.pryrc` or per project `myproject/.pryrc`

```ruby
if defined?(LazyNames)
  Pry.config.hooks.add_hook(:when_started, :lazy_names) do
    LazyNames.load_definitions!
  end
end
```

- If you are using irb, add this line to `~/.irbrc` or per project `myproject/.irbrc`

```ruby
if defined?(LazyNames)
  LazyNames.load_definitions!
end
```

3. And then execute:
```bash
bundle
```

4. Create your own lazy_names config where you define constants
```bash
touch ~/.lazy_names.rb
# or for project-specific config
touch .lazy_names.rb
```

5. Login into your rails or non-rails console
```bash
$ bundle exec rails c # or bin/console
# your shorter version of constants are available now, enjoy!
```

## Configuration

Create a `.lazy_names.rb` file in your project root or home directory:

```ruby
# .lazy_names.rb
MUCC = Models::Users::CreditCard
SPP = Services::PaymentProcessor
CAVUC = Controllers::API::V1::UsersController
```

### File Lookup Priority

LazyNames looks for configuration in this order:

1. `./.lazy_names.rb` (project-specific)
2. `~/.lazy_names.rb` (global)

### Project-Specific Configuration

For project-specific shortcuts, create `.lazy_names.rb` in your project root:

```ruby
# myproject/.lazy_names.rb
MUCC = Models::Users::CreditCard
SPP = Services::PaymentProcessor
```

Don't forget to add it to `.gitignore`:
```sh
echo '.lazy_names.rb' >> .gitignore
```

### Global Configuration

For shortcuts across all projects, create `~/.lazy_names.rb` in your home directory:

```ruby
# ~/.lazy_names.rb
# Add constants you use across multiple projects
AR = ActiveRecord
AM = ActionMailer
```

### Validation

LazyNames validates each line:

- ✅ Must be a constant assignment: `SHORT = Full::Constant::Path`
- ✅ Constant must exist in your application
- ⚠️ Invalid lines are skipped with a warning

### Examples

```ruby
# Comments are allowed
MUCC = Models::Users::CreditCard

# Blank lines are fine

SPP = Services::PaymentProcessor

# Underscores and numbers in short names
API_V1 = API::V1
CACHE2 = Cache::RedisCache
```

## Migrating from v1.x to v2.0

LazyNames v2.0 removes YAML support in favor of plain Ruby.

### Quick Conversion

**Old** (`.lazy_names.yml`):
```yaml
---
definitions:
  'Models::User': 'MU'
  'Services::EmailSender': 'SES'
```

**New** (`.lazy_names.rb`):
```ruby
MU = Models::User
SES = Services::EmailSender
```

### Conversion Script

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

Then:
1. Run the script: `ruby convert_to_v2.rb`
2. Review `.lazy_names.rb`
3. Delete `.lazy_names.yml`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
After you make changes ensure to run `rake rubocop` to check if your code meets linter standards.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zhisme/lazy_names.
Ensure the CI build is green by validating tests are passing and coverage is not decreased.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
