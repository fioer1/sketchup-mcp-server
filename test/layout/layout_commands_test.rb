# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require 'zip'
require_relative '../../src/su_mcp/layout/layout_commands'

class LayoutCommandsTest < Minitest::Test
  def setup
    @commands = SU_MCP::Layout::LayoutCommands.new
  end

  def test_layout_get_document_info_returns_reader_summary
    with_layout_archive do |path|
      result = @commands.layout_get_document_info('path' => path)

      assert_equal(true, result[:success])
      assert_equal(2, result[:pageCount])
      assert_equal(path, result[:path])
    end
  end

  def test_layout_list_pages_returns_ordered_pages
    with_layout_archive do |path|
      result = @commands.layout_list_pages('path' => path)

      assert_equal(true, result[:success])
      assert_equal(['Cover Page', 'FLOORPLAN (PROPOSED)'], result[:pages].map { |page| page[:name] })
    end
  end

  def test_layout_inspect_page_returns_named_page
    with_layout_archive do |path|
      result = @commands.layout_inspect_page(
        'path' => path,
        'pageName' => 'FLOORPLAN (PROPOSED)'
      )

      assert_equal(true, result[:success])
      assert_equal(1, result.dig(:page, :index))
      assert_includes(result[:textSnippets], 'Kitchen Note')
    end
  end

  def test_layout_find_text_returns_matches
    with_layout_archive do |path|
      result = @commands.layout_find_text('path' => path, 'query' => 'kitchen')

      assert_equal(true, result[:success])
      assert_equal(1, result[:matchCount])
    end
  end

  def test_missing_path_refuses
    result = @commands.layout_get_document_info({})

    assert_refusal(result, 'missing_path')
  end

  def test_missing_file_refuses
    result = @commands.layout_get_document_info('path' => 'H:/missing/nope.layout')

    assert_refusal(result, 'layout_file_not_found')
  end

  def test_invalid_extension_refuses
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'sample.txt')
      File.write(path, 'not layout')

      result = @commands.layout_get_document_info('path' => path)

      assert_refusal(result, 'invalid_layout_extension')
    end
  end

  def test_unreadable_archive_refuses
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'broken.layout')
      File.write(path, 'not zip')

      result = @commands.layout_get_document_info('path' => path)

      assert_refusal(result, 'layout_archive_unreadable')
    end
  end

  def test_missing_page_selector_refuses
    with_layout_archive do |path|
      result = @commands.layout_inspect_page('path' => path)

      assert_refusal(result, 'invalid_page_selector')
    end
  end

  def test_unknown_page_refuses
    with_layout_archive do |path|
      result = @commands.layout_inspect_page('path' => path, 'pageName' => 'NO SUCH PAGE')

      assert_refusal(result, 'layout_page_not_found')
    end
  end

  private

  def assert_refusal(result, reason)
    assert_equal(false, result[:success])
    assert_equal(reason, result.dig(:refusal, :reason))
    assert(result.dig(:refusal, :message))
    assert(result.dig(:refusal, :details))
  end

  def with_layout_archive
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'sample.layout')
      Zip::File.open(path, create: true) do |zip|
        zip.get_output_stream('pages/page-001.xml') do |io|
          io.write('<page name="Cover Page" width="17" height="11"><text>Cover Title</text></page>')
        end
        zip.get_output_stream('pages/page-002.xml') do |io|
          io.write('<page name="FLOORPLAN (PROPOSED)"><text>Kitchen Note</text></page>')
        end
      end

      yield path
    end
  end
end
