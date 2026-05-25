# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/mcp_runtime_lifecycle_observer'

class McpRuntimeLifecycleObserverTest < Minitest::Test
  def test_on_quit_requests_runtime_shutdown
    shutdown_reasons = []
    observer = build_observer(shutdown_reasons: shutdown_reasons)

    observer.onQuit

    assert_equal(['SketchUp quit'], shutdown_reasons)
  end

  def test_on_unload_extension_stops_only_for_this_extension
    shutdown_reasons = []
    observer = build_observer(shutdown_reasons: shutdown_reasons)

    observer.onUnloadExtension('Other Extension')
    observer.onUnloadExtension('SketchUp MCP')

    assert_equal(['extension unload'], shutdown_reasons)
  end

  def test_shutdown_failures_are_logged_and_do_not_escape_sketchup_callback
    messages = []
    observer = SU_MCP::McpRuntimeLifecycleObserver.new(
      extension_name: 'SketchUp MCP',
      shutdown_callback: ->(_reason) { raise 'socket close failed' },
      logger: ->(message) { messages << message }
    )

    observer.onQuit

    assert_includes(messages.first, 'socket close failed')
  end

  private

  def build_observer(shutdown_reasons:)
    SU_MCP::McpRuntimeLifecycleObserver.new(
      extension_name: 'SketchUp MCP',
      shutdown_callback: ->(reason) { shutdown_reasons << reason },
      logger: ->(_message) {}
    )
  end
end
