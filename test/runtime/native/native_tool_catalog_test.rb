# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../src/su_mcp/runtime/native/native_tool_catalog'

class NativeToolCatalogTest < Minitest::Test
  READ_ONLY_LAYOUT_TOOLS = %w[
    layout_get_document_info
    layout_list_pages
    layout_inspect_page
    layout_find_text
    layout_validate_document
  ].freeze

  WRITE_LAYOUT_TOOLS = %w[
    layout_copy_document
    layout_replace_text
  ].freeze

  def test_catalog_exposes_read_only_layout_tools
    tools = SU_MCP::NativeToolCatalog.new.entries
    names = tools.map { |tool| tool.fetch(:name) }

    READ_ONLY_LAYOUT_TOOLS.each do |name|
      assert_includes(names, name)
      tool = tools.find { |entry| entry.fetch(:name) == name }
      assert_equal('first_class', tool.fetch(:classification))
      assert_equal(true, tool.dig(:metadata, :annotations, :read_only_hint))
      assert_equal(false, tool.dig(:metadata, :annotations, :destructive_hint))
      assert_includes(tool.dig(:input_schema, :required), 'path')
    end
  end

  def test_catalog_exposes_safe_write_layout_tools
    tools = SU_MCP::NativeToolCatalog.new.entries
    names = tools.map { |tool| tool.fetch(:name) }

    WRITE_LAYOUT_TOOLS.each do |name|
      assert_includes(names, name)
      tool = tools.find { |entry| entry.fetch(:name) == name }
      assert_equal('first_class', tool.fetch(:classification))
      assert_equal(false, tool.dig(:metadata, :annotations, :read_only_hint))
      assert_equal(false, tool.dig(:metadata, :annotations, :destructive_hint))
      assert_includes(tool.dig(:input_schema, :required), 'sourcePath')
      assert_includes(tool.dig(:input_schema, :required), 'outputPath')
    end
  end

  def test_layout_inspect_page_schema_accepts_page_name_or_index
    tool = SU_MCP::NativeToolCatalog
           .new
           .entries
           .find { |entry| entry.fetch(:name) == 'layout_inspect_page' }

    properties = tool.fetch(:input_schema).fetch(:properties)
    assert_includes(properties.keys, :pageName)
    assert_includes(properties.keys, :pageIndex)
  end

  def test_layout_find_text_schema_requires_query
    tool = SU_MCP::NativeToolCatalog
           .new
           .entries
           .find { |entry| entry.fetch(:name) == 'layout_find_text' }

    assert_includes(tool.fetch(:input_schema).fetch(:required), 'query')
  end

  def test_layout_copy_document_schema_requires_source_and_output
    tool = tool_named('layout_copy_document')

    assert_equal(%w[sourcePath outputPath], tool.fetch(:input_schema).fetch(:required))
    properties = tool.fetch(:input_schema).fetch(:properties)
    assert_includes(properties.keys, :sourcePath)
    assert_includes(properties.keys, :outputPath)
    assert_includes(properties.keys, :overwriteOutput)
  end

  def test_layout_replace_text_schema_requires_text_fields
    tool = tool_named('layout_replace_text')

    assert_equal(%w[sourcePath outputPath findText replaceText], tool.fetch(:input_schema).fetch(:required))
    properties = tool.fetch(:input_schema).fetch(:properties)
    assert_includes(properties.keys, :allowNoop)
  end

  def test_layout_validate_document_schema_requires_path
    tool = tool_named('layout_validate_document')

    assert_equal(['path'], tool.fetch(:input_schema).fetch(:required))
  end

  private

  def tool_named(name)
    SU_MCP::NativeToolCatalog
      .new
      .entries
      .find { |entry| entry.fetch(:name) == name }
  end
end
