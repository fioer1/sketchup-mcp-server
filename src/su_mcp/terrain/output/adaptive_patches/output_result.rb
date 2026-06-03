# frozen_string_literal: true

module SU_MCP
  module Terrain
    module AdaptivePatches
      OutputResult = Struct.new(
        :result,
        :timing,
        :seam_validation_summary,
        keyword_init: true
      )
    end
  end
end
