# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    class SchemaDumper < SchemaDumper # :nodoc:
      def self.create(connection, options)
        new(connection, options)
      end

      private
        def column_spec(column)
          [schema_type_with_virtual(column), prepare_column_options(column)]
        end

        def column_spec_for_primary_key(column)
          Rails.logger.info("Column instance")
          Rails.logger.info(column.inspect)
          return {} if default_primary_key?(column)
          Rails.logger.info("Column Spec for Primary Key")
          spec = { id: schema_type(column).inspect }
          Rails.logger.info(spec)
          spec.merge!(prepare_column_options(column).except!(:null, :comment))
          Rails.logger.info(spec)
          spec[:default] ||= "nil" if explicit_primary_key_default?(column)
          spec
        end

        def prepare_column_options(column)
          spec = {}
          spec[:limit] = schema_limit(column)
          spec[:precision] = schema_precision(column)
          spec[:scale] = schema_scale(column)
          spec[:default] = schema_default(column)
          spec[:null] = "false" unless column.null
          spec[:collation] = schema_collation(column)
          spec[:comment] = column.comment.inspect if column.comment.present?
          spec.compact!
          spec
        end

        def default_primary_key?(column)
          schema_type(column) == :bigint
        end

        def explicit_primary_key_default?(column)
          false
        end

        def schema_type_with_virtual(column)
          if @connection.supports_virtual_columns? && column.virtual?
            :virtual
          else
            schema_type(column)
          end
        end

        def schema_type(column)
          if column.bigint?
            :bigint
          else
            column.type
          end
        end

        def schema_limit(column)
          limit = column.limit unless column.bigint?
          limit.inspect if limit && limit != @connection.native_database_types[column.type][:limit]
        end

        def schema_precision(column)
          column.precision.inspect if column.precision
        end

        def schema_scale(column)
          column.scale.inspect if column.scale
        end

        def schema_default(column)
          return unless column.has_default?
          Rails.logger.info("Schema Default")

          type = @connection.lookup_cast_type_from_column(column)
          Rails.logger.info("Type")
          Rails.logger.info(type.inspect)
          default = type.deserialize(column.default)

          if default.nil?
            schema_expression(column)
          else
            type.type_cast_for_schema(default)
          end
        end

        def schema_expression(column)
          Rails.logger.info("Schema Expression")
          Rails.logger.info(column.default_function.inspect)
          "-> { #{column.default_function.inspect} }" if column.default_function
        end

        def schema_collation(column)
          column.collation.inspect if column.collation
        end
    end
  end
end
