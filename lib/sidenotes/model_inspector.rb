# frozen_string_literal: true

module Sidenotes
  class ModelInspector
    attr_reader :model

    def initialize(model)
      @model = model
    end

    SECTION_METHODS = {
      metadata: :metadata,
      columns: :columns,
      indexes: :indexes,
      associations: :associations,
      foreign_keys: :foreign_keys
    }.freeze

    def inspect_model
      return nil unless inspectable?

      data = {}
      sections = Sidenotes.configuration.sections

      SECTION_METHODS.each do |section, method|
        data[section.to_s] = send(method) if sections.include?(section)
      end

      if sections.include?(:check_constraints) && supports_check_constraints?
        data['check_constraints'] = check_constraints
      end

      data
    end

    def inspectable?
      return false if model.abstract_class?
      return false unless model.respond_to?(:table_name)

      model.table_exists?
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      false
    end

    private

    def metadata
      meta = {
        'table_name' => model.table_name,
        'primary_key' => model.primary_key
      }

      add_sti_metadata(meta)
      add_enum_metadata(meta)
      add_encrypted_metadata(meta)

      meta
    end

    def add_sti_metadata(meta)
      return unless model.respond_to?(:inheritance_column)
      return unless model.columns_hash.key?(model.inheritance_column)
      return if model.descends_from_active_record?

      meta['sti_column'] = model.inheritance_column
    end

    def add_enum_metadata(meta)
      return unless model.respond_to?(:defined_enums) && model.defined_enums.any?

      meta['enums'] = model.defined_enums.transform_values { |v| v.is_a?(Hash) ? v.keys : v }
    end

    def add_encrypted_metadata(meta)
      encrypted = model.try(:encrypted_attributes)
      meta['encrypted_attributes'] = encrypted.map(&:to_s) if encrypted&.any?
    end

    def columns
      model.columns.map { |col| build_column_data(col) }
    end

    def build_column_data(col)
      data = { 'name' => col.name, 'type' => col.type.to_s }
      data['default'] = col.default unless col.default.nil?
      data['nullable'] = col.null
      data['limit'] = col.limit if col.limit
      data['precision'] = col.precision if col.precision
      data['scale'] = col.scale if col.scale
      data['comment'] = col.comment if col.respond_to?(:comment) && col.comment
      data
    end

    def indexes
      connection = model.connection
      connection.indexes(model.table_name).map do |idx|
        index_data = {
          'name' => idx.name,
          'columns' => Array(idx.columns)
        }

        index_data['unique'] = idx.unique if idx.unique
        index_data['where'] = idx.where if idx.respond_to?(:where) && idx.where
        index_data['using'] = idx.using.to_s if idx.respond_to?(:using) && idx.using

        index_data
      end
    end

    def associations
      model.reflect_on_all_associations.map { |assoc| build_association_data(assoc) }
    end

    def build_association_data(assoc)
      data = { 'type' => assoc.macro.to_s, 'name' => assoc.name.to_s }
      data['class_name'] = assoc.class_name if assoc.class_name != assoc.name.to_s.classify
      data['foreign_key'] = assoc.foreign_key.to_s if assoc.respond_to?(:foreign_key)
      opts = assoc.respond_to?(:options) ? assoc.options : {}
      data['polymorphic'] = true if opts[:polymorphic]
      data['through'] = opts[:through].to_s if opts[:through]
      data
    end

    def foreign_keys
      connection = model.connection
      return [] unless connection.respond_to?(:foreign_keys)

      connection.foreign_keys(model.table_name).map do |fk|
        fk_data = {
          'from_column' => fk.column,
          'to_table' => fk.to_table,
          'to_column' => fk.primary_key
        }

        fk_data['name'] = fk.name if fk.name
        fk_data['on_delete'] = fk.on_delete.to_s if fk.on_delete
        fk_data['on_update'] = fk.on_update.to_s if fk.on_update

        fk_data
      end
    end

    def check_constraints
      connection = model.connection
      return [] unless connection.respond_to?(:check_constraints)

      connection.check_constraints(model.table_name).map do |cc|
        {
          'name' => cc.name,
          'expression' => cc.expression
        }
      end
    rescue NotImplementedError
      []
    end

    def supports_check_constraints?
      model.connection.respond_to?(:check_constraints)
    rescue StandardError
      false
    end
  end
end
