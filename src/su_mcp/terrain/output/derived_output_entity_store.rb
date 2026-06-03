# frozen_string_literal: true

require 'set'

require_relative 'derived_output_attributes'

module SU_MCP
  module Terrain
    # Owns SketchUp entity traversal, mutation, and metadata for generated terrain output.
    class DerivedOutputEntityStore
      include DerivedOutputAttributes

      def output_attribute(entity, key)
        entity.get_attribute(DICTIONARY, key)
      end

      def derived_output?(entity)
        entity.respond_to?(:get_attribute) &&
          entity.get_attribute(DICTIONARY, DERIVED_OUTPUT_KEY) == true
      end

      def derived_output_entities(entities)
        entities.to_a.select { |entity| derived_output?(entity) }
      end

      def unsupported_child_types(entities)
        entities.each_with_object([]) do |entity, types|
          next if derived_output?(entity)

          types << entity_type(entity)
        end
      end

      def erase_entities(entities, output_entities)
        return if output_entities.empty?

        if entities.respond_to?(:erase_entities)
          entities.erase_entities(output_entities)
        else
          output_entities.each { |entity| entities.delete_entity(entity) }
        end
      end

      def erase_partial_output(entities, faces)
        erase_entities(entities, faces + edges_owned_only_by(faces))
      end

      def owned_faces_for_cell_window(entities, cell_window)
        derived_faces = derived_output_entities(entities).select do |entity|
          derived_face_entity?(entity)
        end
        return fallback_ownership(:legacy_output) if derived_faces.any? do |face|
          legacy_owned_face?(face)
        end

        faces_by_cell = faces_by_cell_for_window(derived_faces, cell_window)
        return faces_by_cell if faces_by_cell.fetch(:outcome, nil) == :fallback

        owned_faces_in_window(faces_by_cell, cell_window)
      end

      def faces_by_cell_for_window(derived_faces, cell_window)
        faces_by_cell = Hash.new { |hash, key| hash[key] = {} }
        derived_faces.each do |face|
          column = output_attribute(face, GRID_CELL_COLUMN_KEY)
          row = output_attribute(face, GRID_CELL_ROW_KEY)
          triangle_index = output_attribute(face, GRID_TRIANGLE_INDEX_KEY)
          next unless cell_in_window?(cell_window, column, row)

          cell_faces = faces_by_cell[[column, row]]
          return fallback_ownership(:duplicate_ownership) if cell_faces.key?(triangle_index)

          cell_faces[triangle_index] = face
        end
        faces_by_cell
      end

      def owned_faces_in_window(faces_by_cell, cell_window)
        affected_faces = []
        cell_window.each_cell do |column, row|
          cell_faces = faces_by_cell[[column, row]]
          return fallback_ownership(:incomplete_ownership) unless cell_faces.keys.sort == [0, 1]

          affected_faces.push(cell_faces.fetch(0), cell_faces.fetch(1))
        end

        { outcome: :owned, faces: affected_faces }
      end

      def fallback_ownership(reason)
        {
          outcome: :fallback,
          reason: reason
        }
      end

      def cleanup_orphan_derived_edges(entities)
        orphan_edges = derived_output_entities(entities).select do |entity|
          entity.is_a?(Sketchup::Edge) &&
            entity.respond_to?(:faces) &&
            entity.faces.empty?
        end
        erase_entities(entities, orphan_edges)
      end

      def derived_face_entity?(entity)
        entity.is_a?(Sketchup::Face) || entity.respond_to?(:points)
      end

      def mark_derived(entity, ownership: nil, mark_edges: true)
        return entity unless entity.respond_to?(:set_attribute)

        entity.set_attribute(DICTIONARY, DERIVED_OUTPUT_KEY, true)
        entity.hidden = true if entity.is_a?(Sketchup::Edge) && entity.respond_to?(:hidden=)
        mark_ownership(entity, ownership) if ownership
        mark_derived_edges(entity) if mark_edges
        entity
      end

      def mark_adaptive_patch_mesh(mesh, batch_id:, output_plan:, face_count:)
        mark_derived(mesh)
        mesh.set_attribute(DICTIONARY, OUTPUT_KIND_KEY, ADAPTIVE_PATCH_MESH_OUTPUT_KIND)
        mesh.set_attribute(DICTIONARY, REPLACEMENT_BATCH_ID_KEY, batch_id)
        mesh.set_attribute(DICTIONARY, TERRAIN_STATE_DIGEST_KEY, output_plan.state_digest)
        mesh.set_attribute(DICTIONARY, TERRAIN_STATE_REVISION_KEY, output_plan.state_revision)
        mesh.set_attribute(
          DICTIONARY,
          ADAPTIVE_POLICY_FINGERPRINT_KEY,
          output_plan.adaptive_patch_policy.output_policy_fingerprint
        )
        mesh.set_attribute(DICTIONARY, FACE_COUNT_KEY, face_count)
      end

      def mark_unique_derived_edges(faces)
        edges = Set.new
        faces.each do |face|
          next unless face.respond_to?(:edges)

          face.edges.each { |edge| edges.add(edge) }
        end
        edges.each { |edge| mark_derived(edge, mark_edges: false) }
      end

      def entity_type(entity)
        case entity
        when Sketchup::Group
          'group'
        when Sketchup::ComponentInstance
          'component_instance'
        when Sketchup::ConstructionPoint
          'construction_point'
        when Sketchup::Face
          'face'
        when Sketchup::Edge
          'edge'
        else
          entity.class.name.to_s.split('::').last.to_s
        end
      end

      def legacy_owned_face?(face)
        [
          OUTPUT_SCHEMA_VERSION_KEY,
          GRID_CELL_COLUMN_KEY,
          GRID_CELL_ROW_KEY,
          GRID_TRIANGLE_INDEX_KEY
        ].any? { |key| output_attribute(face, key).nil? }
      end

      def cell_in_window?(cell_window, column, row)
        return false unless column.is_a?(Integer) && row.is_a?(Integer)

        column.between?(cell_window.min_column, cell_window.max_column) &&
          row.between?(cell_window.min_row, cell_window.max_row)
      end

      def mark_ownership(entity, ownership)
        return mark_cdt_ownership(entity, ownership) if ownership[:kind] == :cdt_patch
        return mark_adaptive_patch_ownership(entity, ownership) if
          ownership[:kind] == :adaptive_patch

        entity.set_attribute(DICTIONARY, OUTPUT_SCHEMA_VERSION_KEY, OUTPUT_SCHEMA_VERSION)
        entity.set_attribute(DICTIONARY, GRID_CELL_COLUMN_KEY, ownership.fetch(:column))
        entity.set_attribute(DICTIONARY, GRID_CELL_ROW_KEY, ownership.fetch(:row))
        entity.set_attribute(DICTIONARY, GRID_TRIANGLE_INDEX_KEY, ownership.fetch(:triangle_index))
      end

      def mark_adaptive_patch_ownership(entity, ownership)
        entity.set_attribute(DICTIONARY, OUTPUT_KIND_KEY, ADAPTIVE_PATCH_FACE_OUTPUT_KIND)
        entity.set_attribute(DICTIONARY, ADAPTIVE_PATCH_ID_KEY, ownership.fetch(:patch_id))
        entity.set_attribute(
          DICTIONARY,
          ADAPTIVE_PATCH_FACE_INDEX_KEY,
          ownership.fetch(:patch_face_index)
        )
        entity.set_attribute(
          DICTIONARY,
          REPLACEMENT_BATCH_ID_KEY,
          ownership.fetch(:replacement_batch_id)
        )
        entity.set_attribute(DICTIONARY, TERRAIN_STATE_DIGEST_KEY, ownership.fetch(:state_digest))
        entity.set_attribute(
          DICTIONARY,
          ADAPTIVE_POLICY_FINGERPRINT_KEY,
          ownership.fetch(:policy_fingerprint)
        )
      end

      def mark_cdt_ownership(entity, ownership)
        entity.set_attribute(DICTIONARY, OUTPUT_KIND_KEY, CDT_PATCH_OUTPUT_KIND)
        entity.set_attribute(DICTIONARY, CDT_OWNERSHIP_SCHEMA_VERSION_KEY, OUTPUT_SCHEMA_VERSION)
        entity.set_attribute(DICTIONARY, CDT_PATCH_ID_KEY, ownership.fetch(:patch_id))
        entity.set_attribute(
          DICTIONARY,
          CDT_REPLACEMENT_BATCH_ID_KEY,
          ownership.fetch(:replacement_batch_id)
        )
        entity.set_attribute(
          DICTIONARY,
          CDT_PATCH_FACE_INDEX_KEY,
          ownership.fetch(:patch_face_index)
        )
        entity.set_attribute(DICTIONARY, CDT_BORDER_SIDE_KEY, ownership[:side])
        entity.set_attribute(DICTIONARY, CDT_BORDER_SPAN_ID_KEY, ownership[:span_id])
      end

      def mark_derived_edges(entity)
        return unless entity.respond_to?(:edges)

        edges = entity.edges
        return unless edges.respond_to?(:each)

        edges.each { |edge| mark_derived(edge, mark_edges: false) }
      end

      def edges_owned_only_by(faces)
        affected_faces = faces.to_set
        faces.flat_map(&:edges).uniq.select do |edge|
          edge.respond_to?(:faces) &&
            edge.faces.respond_to?(:all?) &&
            edge.faces.all? { |face| affected_faces.include?(face) }
        end
      end
    end
  end
end
