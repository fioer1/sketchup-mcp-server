# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/semantic_test_support'
require_relative '../../src/su_mcp/semantic/surface_frame_evaluator'
require_relative '../../src/su_mcp/semantic/surface_height_sampler'

class SurfaceFrameEvaluatorTest < Minitest::Test
  include SemanticTestSupport

  def setup
    @model = build_semantic_model
    @height_sampler = SU_MCP::Semantic::SurfaceHeightSampler.new
    @frame_evaluator = SU_MCP::Semantic::SurfaceFrameEvaluator.new
  end

  def test_frame_sample_uses_same_internal_units_as_surface_height_sampler
    terrain = @model.active_entities.add_face(
      [0.0, 0.0, 2.0],
      [200.0, 0.0, 2.0],
      [200.0, 120.0, 2.0],
      [0.0, 120.0, 2.0]
    )
    terrain.details[:sample_surface] = {
      x_range: [0.0, 200.0],
      y_range: [0.0, 120.0],
      z: 2.0,
      slope_x: 0.05,
      slope_y: 0.02
    }
    context = @height_sampler.prepare_context(terrain)

    height_z = @height_sampler.sample_z_from_context(
      context: context,
      x_value: 80.0,
      y_value: 50.0
    )
    frame = @frame_evaluator.frame_from_context(
      context: context,
      x_value: 80.0,
      y_value: 50.0
    )

    assert_equal('ready', frame.fetch(:outcome))
    assert_in_delta(height_z, frame.dig(:frame, :origin)[2], 1e-9)
    assert_in_delta(0.998553, frame.dig(:frame, :up_axis)[2], 0.000001)
  end

  def test_runtime_frame_refuses_point_inside_bounds_but_outside_face
    face = Class.new do
      attr_reader :classified_points

      def initialize
        @classified_points = []
      end

      def classify_point(point)
        @classified_points << [point.x.to_f, point.y.to_f, point.z.to_f]
        :outside
      end
    end.new
    context = {
      face_entries: [
        {
          face: face,
          transform_chain: [],
          world_plane: [0.0, 0.0, 1.0, -7.0],
          world_xy_bounds: {
            min_x: 0.0,
            max_x: 100.0,
            min_y: 0.0,
            max_y: 100.0
          }
        }
      ]
    }

    result = @frame_evaluator.frame_from_context(
      context: context,
      x_value: 50.0,
      y_value: 50.0
    )

    assert_equal('refused', result.fetch(:outcome))
    assert_equal('surface_frame_miss', result.dig(:refusal, :code))
    assert_equal([[50.0, 50.0, 7.0]], face.classified_points)
  end
end
