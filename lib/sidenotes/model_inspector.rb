# frozen_string_literal: true

module Sidenotes
  class ModelInspector
    attr_reader :model

    def initialize(model)
      @model = model
    end

    def inspect_model
      return nil unless inspectable?

      data = {}
      config = Sidenotes.configuration

      data["metadata"] = metadata if config.sections.include?(:metadata)
      data["columns"] = columns if config.sections.include?(:columns)
      data["indexes"] = indexes if config.sections.include?(:indexes)
      data["associations"] = associations if config.sections.include?(:associations)
      data["foreign_keys"] = foreign_keys if config.sections.include?(:foreign_keys)
      data["check_constraints"] = check_constraints if config.sections.include?(:check_constraints) && supports_check_constraints?
      data["triggers"] = triggers if config.sections.include?(:triggers)

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
        "table_name" => model.table_name,
        "primary_key" => model.primary_key
      }

      if model.respond_to?(:inheritance_column) && model.columns_hash.key?(model.inheritance_column) && model.descends_from_active_record? == false
        meta["sti_column"] = model.inheritance_column
      end

      if model.respond_to?(:defined_enums) && model.defined_enums.any?
        meta["enums"] = model.defined_enums.transform_values { |v| v.is_a?(Hash) ? v.keys : v }
      end

      if model.respond_to?(:encrypted_attributes) && model.encrypted_attributes.any?
        meta["encrypted_attributes"] = model.encrypted_attributes.map(&:to_s)
      end

      meta
    end

    def columns
      model.columns.map do |col|
        column_data = {
          "name" => col.name,
          "type" => col.type.to_s
        }

        column_data["default"] = col.default unless col.default.nil?
        column_data["nullable"] = col.null
        column_data["limit"] = col.limit if col.limit
        column_data["precision"] = col.precision if col.precision
        column_data["scale"] = col.scale if col.scale
        column_data["comment"] = col.comment if col.respond_to?(:comment) && col.comment

        column_data
      end
    end

    def indexes
      connection = model.connection
      connection.indexes(model.table_name).map do |idx|
        index_data = {
          "name" => idx.name,
          "columns" => Array(idx.columns)
        }

        index_data["unique"] = idx.unique if idx.unique
        index_data["where"] = idx.where if idx.respond_to?(:where) && idx.where
        index_data["using"] = idx.using.to_s if idx.respond_to?(:using) && idx.using

        index_data
      end
    end

    def associations
      model.reflect_on_all_associations.map do |assoc|
        assoc_data = {
          "type" => assoc.macro.to_s,
          "name" => assoc.name.to_s
        }

        assoc_data["class_name"] = assoc.class_name if assoc.class_name != assoc.name.to_s.classify
        assoc_data["foreign_key"] = assoc.foreign_key.to_s if assoc.respond_to?(:foreign_key)
        assoc_data["polymorphic"] = true if assoc.respond_to?(:options) && assoc.options[:polymorphic]
        assoc_data["through"] = assoc.options[:through].to_s if assoc.respond_to?(:options) && assoc.options[:through]

        assoc_data
      end
    end

    def foreign_keys
      connection = model.connection
      return [] unless connection.respond_to?(:foreign_keys)

      connection.foreign_keys(model.table_name).map do |fk|
        fk_data = {
          "from_column" => fk.column,
          "to_table" => fk.to_table,
          "to_column" => fk.primary_key
        }

        fk_data["name"] = fk.name if fk.name
        fk_data["on_delete"] = fk.on_delete.to_s if fk.on_delete
        fk_data["on_update"] = fk.on_update.to_s if fk.on_update

        fk_data
      end
    end

    def check_constraints
      connection = model.connection
      return [] unless connection.respond_to?(:check_constraints)

      connection.check_constraints(model.table_name).map do |cc|
        {
          "name" => cc.name,
          "expression" => cc.expression
        }
      end
    rescue NotImplementedError
      []
    end

    def triggers
      # Triggers are database-specific; provide a hook for custom adapters
      []
    end

    def supports_check_constraints?
      model.connection.respond_to?(:check_constraints)
    rescue StandardError
      false
    end
  end
end
