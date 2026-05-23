# frozen_string_literal: true

require_relative 'builder_refusal'

module SU_MCP
  module Semantic
    # Owns reusable generated SketchUp component definitions for semantic proxy geometry.
    class GeneratedComponentLibrary
      ATTRIBUTE_DICTIONARY = 'su_mcp_generated_component'
      NAMESPACE = 'su_mcp.semantic.generated'

      def definition_for(model:, family:, version:, signature:, generator: nil, rebuild: false)
        definition_name = definition_name(family: family, version: version, signature: signature)
        existing_definition = find_definition(model.definitions, definition_name)
        if existing_definition
          ensure_owned_definition!(
            existing_definition,
            family: family,
            version: version,
            signature: signature
          )
          return existing_definition unless rebuild

          clear_definition!(existing_definition)
          yield existing_definition.entities if block_given?
          return existing_definition
        end

        create_definition(
          model.definitions,
          definition_name,
          family: family,
          version: version,
          signature: signature,
          generator: generator
        ) do |definition|
          yield definition.entities if block_given?
        end
      end

      def definition_name(family:, version:, signature:)
        "SU_MCP #{family} v#{version} #{signature}"
      end

      private

      def find_definition(definitions, name)
        definition = definitions[name] if definitions.respond_to?(:[])
        return definition if definition

        return nil unless definitions.respond_to?(:find)

        definitions.find { |definition| definition.name == name }
      end

      def create_definition(definitions, name, family:, version:, signature:, generator:)
        definition = definitions.add(name)
        stamp_definition!(
          definition,
          family: family,
          version: version,
          signature: signature,
          generator: generator
        )
        yield definition
        definition
      rescue StandardError
        remove_definition(definitions, definition) if definition
        raise
      end

      def stamp_definition!(definition, family:, version:, signature:, generator:)
        {
          'namespace' => NAMESPACE,
          'family' => family.to_s,
          'version' => version.to_s,
          'signature' => signature.to_s,
          'generator' => generator.to_s
        }.each do |key, value|
          definition.set_attribute(ATTRIBUTE_DICTIONARY, key, value)
        end
      end

      def ensure_owned_definition!(definition, family:, version:, signature:)
        return if owned_definition?(
          definition,
          family: family,
          version: version,
          signature: signature
        )

        raise BuilderRefusal.new(
          code: 'generated_definition_ownership_conflict',
          message: 'Generated component definition name is already used by an unowned definition.',
          details: {
            family: family,
            version: version,
            signature: signature
          }
        )
      end

      def owned_definition?(definition, family:, version:, signature:)
        definition.get_attribute(ATTRIBUTE_DICTIONARY, 'namespace') == NAMESPACE &&
          definition.get_attribute(ATTRIBUTE_DICTIONARY, 'family') == family.to_s &&
          definition.get_attribute(ATTRIBUTE_DICTIONARY, 'version') == version.to_s &&
          definition.get_attribute(ATTRIBUTE_DICTIONARY, 'signature') == signature.to_s
      end

      def clear_definition!(definition)
        return definition.clear! if definition.respond_to?(:clear!)

        definition.entities.to_a.each(&:erase!) if definition.entities.respond_to?(:to_a)
      end

      def remove_definition(definitions, definition)
        return definitions.remove(definition) if definitions.respond_to?(:remove)

        definition.entities.to_a.each(&:erase!) if definition.entities.respond_to?(:to_a)
      rescue StandardError
        nil
      end
    end
  end
end
