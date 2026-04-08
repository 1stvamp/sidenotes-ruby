# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-08

### Added

- Initial release
- YAML and JSON annotation output formats
- Column inspection: name, type, default, nullable, limit, precision, scale, comment
- Index inspection: name, columns, unique, where, using
- Association inspection: type, name, class_name, foreign_key, polymorphic, through
- Foreign key and check constraint inspection
- Model metadata: table name, primary key, STI column, enums, encrypted attributes
- Support for STI, polymorphic, HABTM, namespaced, and self-referential models
- Configurable sections, output directory, and exclusion patterns
- Rake tasks: `sidenotes:generate`, `sidenotes:clean`, `sidenotes:model`
- Rails generator: `rails generate sidenotes:install`
- Ruby 3.0+ and Rails 6.1+ support
