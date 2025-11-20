# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-MM-DD

### BREAKING CHANGES
- Removed YAML configuration support (`.lazy_names.yml` no longer supported)
- Configuration now uses plain Ruby files (`.lazy_names.rb`)
- Removed internal classes: `ConfigLoader`, `Config`, `ConfigValidator`, `Definer`, `FindNamespace`
- Users must migrate from YAML to Ruby configuration format

### Added
- Ruby-based configuration with `.lazy_names.rb`
- Constant existence validation at load time (mandatory validation before eval)
- Line-by-line error reporting with line numbers
- Detailed logging for loaded/skipped definitions
- `LineValidator` class for robust syntax validation
- `RubyLoader` class for file loading and evaluation
- Migration guide in README for v1.x users
- Conversion script example for YAML to Ruby migration

### Removed
- YAML configuration support (`.lazy_names.yml`)
- YAML parsing dependencies
- Hash-based configuration abstraction
- Namespace-based configuration (simplified to single file lookup)

### Changed
- Simplified architecture: 140 fewer lines of code
- Direct constant assignment instead of hash definitions
- Better error messages with line numbers and context
- More intuitive Ruby-native configuration

### Migration Guide
See README.md for complete migration instructions. Quick example:

**Before (v1.x)**:
```yaml
---
definitions:
  'Models::User': 'MU'
```

**After (v2.0)**:
```ruby
MU = Models::User
```

## [1.0.0] - 2024-MM-DD

### Added
- Initial release with YAML-based configuration
- Support for global and project-specific configurations
- IRB and Pry integration
- Constant validation and error reporting
