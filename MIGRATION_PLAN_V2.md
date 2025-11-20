# LazyNames v2.0.0 - Implementation Plan

## Overview

LazyNames v2.0 removes YAML configuration in favor of plain Ruby files, making the gem simpler, more intuitive, and Ruby-native.

## Breaking Changes

- **Remove all YAML support** (`.lazy_names.yml` no longer supported)
- **Users must migrate** to `.lazy_names.rb` format
- **Version bump**: 1.0.0 → 2.0.0

---

## Core Concept Change

### Before (v1.x - YAML)
```yaml
# .lazy_names.yml
---
definitions:
  'Models::Users::CreditCard': 'MUCC'
  'Services::PaymentProcessor': 'SPP'
```

### After (v2.0 - Ruby)
```ruby
# .lazy_names.rb
MUCC = Models::Users::CreditCard
SPP = Services::PaymentProcessor
```

**Why?** Just write Ruby - no YAML, no abstraction, no magic. Same syntax you'd use in `.irbrc`/`.pryrc`.

---

## Architecture Changes

### Old Flow (v1.x)
```
LazyNames.load_definitions!
  → FindNamespace
  → ConfigLoader (YAML parsing)
  → Config (hash wrapper)
  → ConfigValidator
  → Definer (eval)
```

**Lines of code**: ~220 lines across 5 files

### New Flow (v2.0)
```
LazyNames.load_definitions!
  → RubyLoader
  → LineValidator (validate & check constant exists)
  → eval each valid line
```

**Lines of code**: ~80 lines across 2 files

**Result**: 140 fewer lines, simpler architecture

---

## Implementation Details

### Step 1: Create LineValidator

**File**: `lib/lazy_names/line_validator.rb` (NEW)

**Responsibilities**:
- Validate assignment pattern: `CONST = Path::To::Constant`
- Left side: Valid constant name (uppercase start, can include `_` and digits)
- Right side: Valid constant path (`::`-separated)
- **MUST check if right-side constant exists** (required, not optional)
- Return validation result with parsed data or error message

**Validation Rules**:
1. ✅ Must match pattern: `CONST = Path::To::Constant`
2. ✅ Left side must be valid constant name (starts with uppercase)
3. ✅ Right side must be valid constant path
4. ✅ Right side constant must exist in the application
5. ✅ Skip blank lines and comments silently
6. ⚠️ Reject method calls, string literals, arbitrary code

**Implementation**:
```ruby
# frozen_string_literal: true

module LazyNames
  class LineValidator
    ASSIGNMENT_PATTERN = /\A\s*([A-Z][A-Z0-9_]*)\s*=\s*([A-Z][A-Za-z0-9_:]*)\s*\z/

    class ValidationResult
      attr_reader :valid, :short_name, :full_constant, :error

      def initialize(valid:, short_name: nil, full_constant: nil, error: nil)
        @valid = valid
        @short_name = short_name
        @full_constant = full_constant
        @error = error
      end

      def valid?
        @valid
      end
    end

    def self.validate(line)
      return skip_result if skip_line?(line)

      match = line.match(ASSIGNMENT_PATTERN)
      return invalid_result("Invalid syntax") unless match

      short_name = match[1]
      full_constant = match[2]

      unless constant_exists?(full_constant)
        return invalid_result("Constant #{full_constant} not found")
      end

      ValidationResult.new(
        valid: true,
        short_name: short_name,
        full_constant: full_constant
      )
    end

    def self.skip_line?(line)
      line.strip.empty? || line.strip.start_with?('#')
    end

    def self.constant_exists?(constant_path)
      Object.const_get(constant_path)
      true
    rescue NameError
      false
    end

    def self.skip_result
      ValidationResult.new(valid: false)
    end

    def self.invalid_result(error)
      ValidationResult.new(valid: false, error: error)
    end

    private_class_method :skip_line?, :constant_exists?, :skip_result, :invalid_result
  end
end
```

---

### Step 2: Create RubyLoader

**File**: `lib/lazy_names/ruby_loader.rb` (NEW)

**Responsibilities**:
- Find `.lazy_names.rb` (project dir → home dir)
- Read file line by line
- Use LineValidator to validate each line
- **Skip lines where constant doesn't exist** (warn user)
- Eval valid lines in provided binding
- Track and report stats (loaded/skipped/errors)

**File Lookup Priority**:
1. `./.lazy_names.rb` (project-specific, no namespace needed)
2. `~/.lazy_names.rb` (global)

**Implementation**:
```ruby
# frozen_string_literal: true

module LazyNames
  class RubyLoader
    CONFIG_FILE = '.lazy_names.rb'

    def self.load!(binding)
      new.load!(binding)
    end

    def initialize
      @loaded_count = 0
      @skipped_count = 0
      @error_count = 0
    end

    def load!(binding)
      path = find_config_file
      unless path
        Logger.warn("No #{CONFIG_FILE} found")
        return
      end

      Logger.info("Loading definitions from #{path}")

      File.readlines(path).each_with_index do |line, index|
        line_number = index + 1
        process_line(line, line_number, binding)
      end

      log_summary
    end

    private

    def find_config_file
      project_config = File.join(Dir.pwd, CONFIG_FILE)
      return project_config if File.exist?(project_config)

      home_config = File.join(Dir.home, CONFIG_FILE)
      return home_config if File.exist?(home_config)

      nil
    end

    def process_line(line, line_number, binding)
      result = LineValidator.validate(line)

      if result.valid?
        eval_line(line, binding)
        @loaded_count += 1
      elsif result.error
        Logger.warn("Line #{line_number}: #{result.error} - #{line.strip}")
        @error_count += 1
      else
        # Blank line or comment - skip silently
        @skipped_count += 1
      end
    rescue StandardError => e
      Logger.warn("Line #{line_number}: #{e.message}")
      @error_count += 1
    end

    def eval_line(line, binding)
      binding.eval(line)
    end

    def log_summary
      Logger.info("Loaded #{@loaded_count} definitions") if @loaded_count > 0
      Logger.warn("Skipped #{@error_count} invalid lines") if @error_count > 0
    end
  end
end
```

---

### Step 3: Update Main Entry Point

**File**: `lib/lazy_names.rb`

**Changes**:
- Remove all old requires
- Add new requires for RubyLoader and LineValidator
- Simplify `load_definitions!` to just call RubyLoader

**Implementation**:
```ruby
# frozen_string_literal: true

require_relative 'lazy_names/version'
require_relative 'lazy_names/logger'
require_relative 'lazy_names/line_validator'
require_relative 'lazy_names/ruby_loader'

module LazyNames
  def self.load_definitions!(top_level_binding = binding)
    RubyLoader.load!(top_level_binding)
  end
end
```

---

### Step 4: Delete Old Files

**Remove these files entirely**:
- `lib/lazy_names/config_loader.rb` (92 lines)
- `lib/lazy_names/config.rb` (42 lines)
- `lib/lazy_names/config_validator.rb` (60 lines)
- `lib/lazy_names/definer.rb` (16 lines)
- `lib/lazy_names/find_namespace.rb` (15 lines)

**Total removed**: ~225 lines

---

### Step 5: Update Gemspec

**File**: `lazy_names.gemspec`

**Changes**:
```ruby
spec.version = '2.0.0'
spec.summary = 'Lazy names for Ruby constants'
spec.description = 'Define short aliases for long constant names using plain Ruby'
```

Remove any YAML-related dependencies if listed.

---

### Step 6: Testing

#### 6.1 LineValidator Tests

**File**: `spec/lazy_names/line_validator_spec.rb` (NEW)

**Test cases**:
- ✅ Validates when constant exists
- ✅ Rejects when constant does not exist
- ✅ Rejects lowercase short name
- ✅ Rejects method calls
- ✅ Rejects string literals
- ✅ Rejects arbitrary code
- ✅ Skips blank lines
- ✅ Skips comments
- ✅ Handles extra whitespace
- ✅ Accepts underscores in constant names
- ✅ Accepts numbers in constant names

#### 6.2 RubyLoader Tests

**File**: `spec/lazy_names/ruby_loader_spec.rb` (NEW)

**Test cases**:
- ✅ Loads constant definitions
- ✅ Skips comments and blank lines
- ✅ Warns and skips lines with nonexistent constants
- ✅ Warns and skips invalid syntax
- ✅ Warns when no config file found
- ✅ Prefers project `.lazy_names.rb` over home directory
- ✅ Uses home directory if project file does not exist

#### 6.3 Integration Tests

**File**: `spec/integration/ruby_config_spec.rb` (NEW)

**Test cases**:
- ✅ Loads and defines constants from `.lazy_names.rb`
- ✅ Handles mixed valid and invalid definitions

#### 6.4 Delete Old Tests

**Remove these test files**:
- `spec/lazy_names/config_loader_spec.rb`
- `spec/lazy_names/config_spec.rb`
- `spec/lazy_names/config_validator_spec.rb`
- `spec/lazy_names/definer_spec.rb`
- `spec/lazy_names/find_namespace_spec.rb`

---

### Step 7: Documentation Updates

#### 7.1 README.md

**Replace all YAML examples with Ruby**

**Add new sections**:

##### Why Plain Ruby?
```markdown
## Why Plain Ruby?

LazyNames v2.0 uses plain Ruby instead of YAML because:

- ✅ **Intuitive**: Same syntax you'd write in `.irbrc`/`.pryrc`
- ✅ **IDE Support**: Syntax highlighting and autocomplete work out of the box
- ✅ **Validation**: Constants are validated at load time
- ✅ **Simpler**: No YAML parsing, no extra abstraction
- ✅ **Ruby-native**: Write Ruby to configure Ruby
```

##### Configuration
```markdown
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
```

##### Migrating from v1.x
```markdown
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

```ruby
#!/usr/bin/env ruby
# convert_to_v2.rb

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

Run the script and delete the old `.lazy_names.yml` file.
```

#### 7.2 CHANGELOG.md

**Add v2.0.0 entry**:
```markdown
## [2.0.0] - 2025-MM-DD

### BREAKING CHANGES
- Removed YAML configuration support
- Configuration now uses plain Ruby files (`.lazy_names.rb`)
- Removed internal classes: `ConfigLoader`, `Config`, `ConfigValidator`, `Definer`, `FindNamespace`

### Added
- Ruby-based configuration with `.lazy_names.rb`
- Constant existence validation at load time
- Line-by-line error reporting with line numbers
- Detailed logging for loaded/skipped definitions
- `LineValidator` class for robust syntax validation
- `RubyLoader` class for file loading and evaluation

### Removed
- YAML configuration support (`.lazy_names.yml`)
- YAML parsing dependencies
- Hash-based configuration abstraction

### Changed
- Simplified architecture: 140 fewer lines of code
- Direct constant assignment instead of hash definitions
- Better error messages with line numbers

### Migration
- See README for migration guide from v1.x
- Use provided conversion script to migrate from YAML to Ruby
- Example: `MUCC = Models::Users::CreditCard` instead of YAML hash
```

---

### Step 8: Create Migration Script

**File**: `bin/convert_to_v2` (NEW, executable)

**Purpose**: Help users migrate from `.lazy_names.yml` to `.lazy_names.rb`

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

def convert_yaml_to_ruby
  yaml_file = '.lazy_names.yml'
  ruby_file = '.lazy_names.rb'

  unless File.exist?(yaml_file)
    puts "No #{yaml_file} found in current directory"
    exit 1
  end

  if File.exist?(ruby_file)
    puts "#{ruby_file} already exists. Remove it first or merge manually."
    exit 1
  end

  begin
    yaml = YAML.load_file(yaml_file)
    definitions = extract_definitions(yaml)

    File.open(ruby_file, 'w') do |f|
      f.puts "# Converted from .lazy_names.yml"
      f.puts ""
      definitions.each do |full, short|
        f.puts "#{short} = #{full}"
      end
    end

    puts "✓ Converted #{definitions.size} definitions to #{ruby_file}"
    puts ""
    puts "Next steps:"
    puts "  1. Review #{ruby_file}"
    puts "  2. Delete #{yaml_file}"
    puts "  3. Update lazy_names gem to v2.0"
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end

def extract_definitions(yaml)
  if yaml['definitions']
    yaml['definitions']
  elsif yaml.is_a?(Hash) && yaml.values.first.is_a?(Hash)
    yaml.values.first['definitions'] || {}
  else
    {}
  end
end

convert_yaml_to_ruby
```

Make executable: `chmod +x bin/convert_to_v2`

---

## Implementation Checklist

### Phase 1: Core Implementation
- [ ] Create `lib/lazy_names/line_validator.rb` with mandatory constant checking
- [ ] Create `lib/lazy_names/ruby_loader.rb` with file loading and eval
- [ ] Update `lib/lazy_names.rb` to use new classes
- [ ] Remove old files: `config_loader.rb`, `config.rb`, `config_validator.rb`, `definer.rb`, `find_namespace.rb`

### Phase 2: Tests
- [ ] Create `spec/lazy_names/line_validator_spec.rb`
- [ ] Create `spec/lazy_names/ruby_loader_spec.rb`
- [ ] Create `spec/integration/ruby_config_spec.rb`
- [ ] Delete old test files
- [ ] Run test suite and ensure all pass

### Phase 3: Documentation
- [ ] Update README.md with Ruby examples
- [ ] Add "Why Plain Ruby?" section
- [ ] Add migration guide to README
- [ ] Update CHANGELOG.md with v2.0.0 entry
- [ ] Update all code examples throughout docs

### Phase 4: Packaging
- [ ] Update `lazy_names.gemspec` to version 2.0.0
- [ ] Update description to reflect Ruby (not YAML)
- [ ] Create `bin/convert_to_v2` migration script
- [ ] Make migration script executable

### Phase 5: Final Verification
- [ ] Test manually with sample `.lazy_names.rb`
- [ ] Verify all old YAML code is removed
- [ ] Run full test suite
- [ ] Test in actual IRB/Pry session
- [ ] Review all documentation changes
- [ ] Verify no YAML dependencies remain

---

## File Changes Summary

| File | Action | Lines | Description |
|------|--------|-------|-------------|
| `lib/lazy_names/line_validator.rb` | CREATE | ~60 | Validate constant assignments |
| `lib/lazy_names/ruby_loader.rb` | CREATE | ~70 | Load and eval Ruby config |
| `lib/lazy_names.rb` | MODIFY | ~10 | Use new loader |
| `lib/lazy_names/config_loader.rb` | DELETE | -92 | Remove YAML support |
| `lib/lazy_names/config.rb` | DELETE | -42 | No longer needed |
| `lib/lazy_names/config_validator.rb` | DELETE | -60 | Validation in LineValidator |
| `lib/lazy_names/definer.rb` | DELETE | -16 | Eval handles definition |
| `lib/lazy_names/find_namespace.rb` | DELETE | -15 | No namespacing needed |
| `lazy_names.gemspec` | MODIFY | ~5 | Version 2.0.0 |
| `README.md` | MODIFY | ~50 | Ruby examples, migration guide |
| `CHANGELOG.md` | MODIFY | ~20 | Add 2.0.0 entry |
| `bin/convert_to_v2` | CREATE | ~45 | Migration script |
| `spec/lazy_names/line_validator_spec.rb` | CREATE | ~80 | Test validator |
| `spec/lazy_names/ruby_loader_spec.rb` | CREATE | ~100 | Test loader |
| `spec/integration/ruby_config_spec.rb` | CREATE | ~40 | Integration tests |
| `spec/lazy_names/config_loader_spec.rb` | DELETE | -80 | Old tests |
| `spec/lazy_names/config_spec.rb` | DELETE | -40 | Old tests |
| `spec/lazy_names/config_validator_spec.rb` | DELETE | -60 | Old tests |
| `spec/lazy_names/definer_spec.rb` | DELETE | -20 | Old tests |
| `spec/lazy_names/find_namespace_spec.rb` | DELETE | -15 | Old tests |

**Summary**:
- **Added**: ~465 lines (new implementation + tests + docs)
- **Removed**: ~440 lines (old implementation + tests)
- **Net change**: +25 lines, but much simpler architecture

---

## Benefits of v2.0

### For Users
✅ **More intuitive**: Write Ruby, not YAML
✅ **Better IDE support**: Syntax highlighting works
✅ **Immediate validation**: Know if constants exist at load time
✅ **Clearer errors**: Line numbers and specific error messages
✅ **Familiar syntax**: Same as `.irbrc`/`.pryrc`

### For Maintainers
✅ **Simpler codebase**: 140 fewer lines
✅ **No YAML dependency**: One less gem to worry about
✅ **Easier to test**: Direct Ruby evaluation
✅ **Clearer code flow**: 2 classes instead of 5
✅ **Better error handling**: Line-by-line validation

---

## Testing Strategy

### Manual Testing
1. Create test project with constants:
   ```ruby
   module Models
     class User; end
   end
   ```

2. Create `.lazy_names.rb`:
   ```ruby
   MU = Models::User
   ```

3. Start IRB with:
   ```ruby
   require 'lazy_names'
   LazyNames.load_definitions!
   ```

4. Verify `MU` is defined and equals `Models::User`

### Automated Testing
- Unit tests for LineValidator
- Unit tests for RubyLoader
- Integration tests for full flow
- Edge cases: missing constants, invalid syntax, blank lines, comments

---

## Migration Path for Users

### Step 1: Install v2.0
```bash
gem install lazy_names -v 2.0.0
# or in Gemfile
gem 'lazy_names', '~> 2.0'
```

### Step 2: Convert Configuration
```bash
# Use provided script
ruby bin/convert_to_v2

# Or manually convert
# .lazy_names.yml → .lazy_names.rb
```

### Step 3: Test
```bash
# Start IRB/Pry and verify constants load
irb
> require 'lazy_names'
> LazyNames.load_definitions!
```

### Step 4: Clean Up
```bash
# Remove old YAML file
rm .lazy_names.yml
```

---

## Risk Assessment

### Low Risk
- Well-tested validation logic
- Clear error messages
- Graceful handling of invalid lines
- Non-destructive (only reads files)

### Medium Risk
- Breaking change requires user action
- Users must migrate configurations

### Mitigation
- Clear migration guide
- Automated conversion script
- Detailed documentation
- Version bump signals breaking change

---

## Success Criteria

✅ All YAML code removed
✅ `.lazy_names.rb` files load successfully
✅ Constants validated before eval
✅ Invalid constants warned and skipped
✅ All tests pass (100% coverage)
✅ README updated with Ruby examples
✅ Migration script provided and tested
✅ Version bumped to 2.0.0
✅ No regressions in functionality

---

## Timeline Estimate

- **Phase 1 (Core)**: 4-5 hours
- **Phase 2 (Tests)**: 3-4 hours
- **Phase 3 (Docs)**: 2-3 hours
- **Phase 4 (Packaging)**: 1 hour
- **Phase 5 (Verification)**: 1-2 hours

**Total**: 11-15 hours for complete implementation

---

## Questions to Consider

1. Should we provide backward compatibility mode (support both YAML and Ruby)?
   - **Decision**: No. Clean break for simpler codebase.

2. Should we validate that short names don't conflict with existing constants?
   - **Decision**: Warn but allow (Ruby will raise if truly conflicting).

3. Should we support namespace comments in global config?
   - **Decision**: Not in v2.0. Add if users request it.

4. Should we allow arbitrary Ruby code in config files?
   - **Decision**: No. Only constant assignments for security.

---

## Post-Release Tasks

- [ ] Announce v2.0 release
- [ ] Update gem documentation on RubyGems
- [ ] Create release notes on GitHub
- [ ] Monitor for user issues
- [ ] Update examples in blog posts/tutorials
- [ ] Consider deprecating v1.x support timeline

---

## Conclusion

LazyNames v2.0 represents a significant simplification of the gem while making it more intuitive and Ruby-native. By removing YAML abstraction and letting users write plain Ruby, we reduce complexity, improve the user experience, and make the codebase easier to maintain.

The breaking change is justified by the substantial benefits and the straightforward migration path provided.
