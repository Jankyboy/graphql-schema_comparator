module GraphQL
  module SchemaComparator
    module Diff
      class Schema
        def initialize(old_schema, new_schema)
          @old_schema = old_schema
          @new_schema = new_schema

          @old_types = old_schema.types
          @new_types = new_schema.types

          @old_directives = old_schema.directives
          @new_directives = new_schema.directives
        end

        def diff
          changes = []

          # Removed and Added Types
          changes += removed_types.map { |type| Changes::TypeRemoved.new(type) }
          changes += added_types.map { |type| Changes::TypeAdded.new(type) }

          # Type Diff for common types
          each_common_type do |old_type, new_type|
            changes += changes_in_type(old_type, new_type)
          end

          # Diff Schemas
          changes += changes_in_schema

          # Diff Directives
          changes += changes_in_directives

          changes
        end

        def changes_in_type(old_type, new_type)
          changes = []

          if old_type.kind != new_type.kind
            changes << Changes::TypeKindChanged.new(old_type, new_type)
          else
            case old_type
            when GraphQL::EnumType
              changes += Diff::Enum.new(old_type, new_type).diff
            when GraphQL::UnionType
              changes += Diff::Union.new(old_type, new_type).diff
            when GraphQL::InputObjectType
              changes += Diff::InputObject.new(old_type, new_type).diff
            when GraphQL::ObjectType
              changes += Diff::ObjectType.new(old_type, new_type).diff
            when GraphQL::InterfaceType
              changes += Diff::Interface.new(old_type, new_type).diff
            end
          end

          if old_type.description != new_type.description
            changes << Changes::TypeDescriptionChanged.new(old_type, new_type)
          end

          changes
        end

        def changes_in_schema
          changes = []

          if old_schema.query != new_schema.query
            changes << Changes::SchemaQueryTypeChanged.new(old_schema, new_schema)
          end

          if old_schema.mutation != new_schema.mutation
            changes << Changes::SchemaMutationTypeChanged.new(old_schema, new_schema)
          end

          if old_schema.subscription != new_schema.subscription
            changes << Changes::SchemaSubscriptionTypeChanged.new(old_schema, new_schema)
          end

          changes
        end

        def changes_in_directives
          changes = []

          changes += removed_directives.map { |directive| Changes::DirectiveRemoved.new(directive) }
          changes += added_directives.map { |directive| Changes::DirectiveAdded.new(directive) }

          each_common_directive do |old_directive, new_directive|
            changes += Diff::Directive.new(old_directive, new_directive).diff
          end

          changes
        end

        private

        def each_common_type(&block)
          intersection = old_types.keys & new_types.keys
          intersection.each do |common_type_name|
            old_type = old_schema.types[common_type_name]
            new_type = new_schema.types[common_type_name]

            block.call(old_type, new_type)
          end
        end

        def removed_types
          (old_types.keys - new_types.keys).map { |type_name| old_schema.types[type_name] }
        end

        def added_types
          (new_types.keys - old_types.keys).map { |type_name| new_schema.types[type_name] }
        end

        def removed_directives
          (old_directives.keys - new_directives.keys).map { |directive_name| old_schema.directives[directive_name] }
        end

        def added_directives
          (new_directives.keys - old_directives.keys).map { |directive_name| new_schema.directives[directive_name] }
        end

        def each_common_directive(&block)
          intersection = old_directives.keys & new_directives.keys
          intersection.each do |common_directive_name|
            old_directive = old_schema.directives[common_directive_name]
            new_directive = new_schema.directives[common_directive_name]

            block.call(old_directive, new_directive)
          end
        end

        attr_reader :old_schema, :new_schema, :old_types, :new_types, :old_directives, :new_directives
      end
    end
  end
end
