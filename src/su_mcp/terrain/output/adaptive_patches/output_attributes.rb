# frozen_string_literal: true

require_relative '../derived_output_attributes'

module SU_MCP
  module Terrain
    module AdaptivePatches
      OUTPUT_KIND_KEY = DerivedOutputAttributes::OUTPUT_KIND_KEY
      DERIVED_OUTPUT_KEY = DerivedOutputAttributes::DERIVED_OUTPUT_KEY
      ADAPTIVE_PATCH_MESH_OUTPUT_KIND =
        DerivedOutputAttributes::ADAPTIVE_PATCH_MESH_OUTPUT_KIND
      ADAPTIVE_PATCH_FACE_OUTPUT_KIND =
        DerivedOutputAttributes::ADAPTIVE_PATCH_FACE_OUTPUT_KIND
      ADAPTIVE_PATCH_REGISTRY_KEY = DerivedOutputAttributes::ADAPTIVE_PATCH_REGISTRY_KEY
      ADAPTIVE_PATCH_ID_KEY = DerivedOutputAttributes::ADAPTIVE_PATCH_ID_KEY
      ADAPTIVE_PATCH_FACE_INDEX_KEY = DerivedOutputAttributes::ADAPTIVE_PATCH_FACE_INDEX_KEY
      ADAPTIVE_POLICY_FINGERPRINT_KEY =
        DerivedOutputAttributes::ADAPTIVE_POLICY_FINGERPRINT_KEY
      REPLACEMENT_BATCH_ID_KEY = DerivedOutputAttributes::REPLACEMENT_BATCH_ID_KEY
      TERRAIN_STATE_DIGEST_KEY = DerivedOutputAttributes::TERRAIN_STATE_DIGEST_KEY
    end
  end
end
