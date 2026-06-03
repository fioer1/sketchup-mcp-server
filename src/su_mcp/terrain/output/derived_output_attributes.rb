# frozen_string_literal: true

module SU_MCP
  module Terrain
    # Attribute names used to identify and own disposable terrain output.
    module DerivedOutputAttributes
      DICTIONARY = 'su_mcp_terrain'
      DERIVED_OUTPUT_KEY = 'derivedOutput'
      OUTPUT_SCHEMA_VERSION = 1
      OUTPUT_SCHEMA_VERSION_KEY = 'outputSchemaVersion'
      GRID_CELL_COLUMN_KEY = 'gridCellColumn'
      GRID_CELL_ROW_KEY = 'gridCellRow'
      GRID_TRIANGLE_INDEX_KEY = 'gridTriangleIndex'
      OUTPUT_KIND_KEY = 'outputKind'
      ADAPTIVE_PATCH_MESH_OUTPUT_KIND = 'adaptive_patch_mesh'
      ADAPTIVE_PATCH_FACE_OUTPUT_KIND = 'adaptive_patch_face'
      ADAPTIVE_PATCH_REGISTRY_KEY = 'adaptivePatchRegistry'
      ADAPTIVE_PATCH_ID_KEY = 'adaptivePatchId'
      ADAPTIVE_PATCH_FACE_INDEX_KEY = 'adaptivePatchFaceIndex'
      ADAPTIVE_POLICY_FINGERPRINT_KEY = 'adaptiveOutputPolicyFingerprint'
      REPLACEMENT_BATCH_ID_KEY = 'replacementBatchId'
      TERRAIN_STATE_DIGEST_KEY = 'terrainStateDigest'
      TERRAIN_STATE_REVISION_KEY = 'terrainStateRevision'
      FACE_COUNT_KEY = 'faceCount'
      CDT_PATCH_OUTPUT_KIND = 'cdt_patch_face'
      CDT_OWNERSHIP_SCHEMA_VERSION_KEY = 'cdtOwnershipSchemaVersion'
      CDT_PATCH_ID_KEY = 'cdtPatchId'
      CDT_REPLACEMENT_BATCH_ID_KEY = 'cdtReplacementBatchId'
      CDT_PATCH_FACE_INDEX_KEY = 'cdtPatchFaceIndex'
      CDT_BORDER_SIDE_KEY = 'cdtBorderSide'
      CDT_BORDER_SPAN_ID_KEY = 'cdtBorderSpanId'
    end
  end
end
