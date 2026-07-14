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

  def test_layout_copy_document_writes_output_and_validates_it
    with_layout_archive do |path|
      output_path = File.join(File.dirname(path), 'copy.layout')

      result = @commands.layout_copy_document('sourcePath' => path, 'outputPath' => output_path)

      assert_equal(true, result[:success])
      assert_equal(output_path, result[:outputPath])
      assert_equal(2, result.dig(:validation, :pageCount))
      assert(File.exist?(output_path))
    end
  end

  def test_layout_replace_text_writes_output_with_replacement_evidence
    with_layout_archive do |path|
      output_path = File.join(File.dirname(path), 'replaced.layout')

      result = @commands.layout_replace_text(
        'sourcePath' => path,
        'outputPath' => output_path,
        'findText' => 'Kitchen Note',
        'replaceText' => 'Pantry Note'
      )

      assert_equal(true, result[:success])
      assert_equal(1, result[:replacementCount])
      assert_equal(2, result.dig(:validation, :pageCount))
      inspect = @commands.layout_inspect_page('path' => output_path, 'pageName' => 'FLOORPLAN (PROPOSED)')
      assert_includes(inspect[:textSnippets], 'Pantry Note')
    end
  end

  def test_layout_validate_document_returns_page_names
    with_layout_archive do |path|
      result = @commands.layout_validate_document('path' => path)

      assert_equal(true, result[:success])
      assert_equal(2, result[:pageCount])
      assert_equal(['Cover Page', 'FLOORPLAN (PROPOSED)'], result[:pageNames])
    end
  end

  def test_layout_copy_document_refuses_missing_source_path
    result = @commands.layout_copy_document('outputPath' => 'H:/out.layout')

    assert_refusal(result, 'missing_source_path')
  end

  def test_layout_copy_document_refuses_missing_output_path
    result = @commands.layout_copy_document('sourcePath' => 'H:/source.layout')

    assert_refusal(result, 'missing_output_path')
  end

  def test_layout_copy_document_refuses_same_source_and_output
    with_layout_archive do |path|
      result = @commands.layout_copy_document('sourcePath' => path, 'outputPath' => path)

      assert_refusal(result, 'layout_output_same_as_source')
    end
  end

  def test_layout_copy_document_refuses_existing_output
    with_layout_archive do |path|
      output_path = File.join(File.dirname(path), 'existing.layout')
      File.write(output_path, 'existing')

      result = @commands.layout_copy_document('sourcePath' => path, 'outputPath' => output_path)

      assert_refusal(result, 'layout_output_exists')
    end
  end

  def test_layout_replace_text_refuses_missing_find_text
    with_layout_archive do |path|
      result = @commands.layout_replace_text(
        'sourcePath' => path,
        'outputPath' => File.join(File.dirname(path), 'out.layout'),
        'replaceText' => 'Replacement'
      )

      assert_refusal(result, 'missing_find_text')
    end
  end

  def test_layout_replace_text_refuses_no_replacements
    with_layout_archive do |path|
      result = @commands.layout_replace_text(
        'sourcePath' => path,
        'outputPath' => File.join(File.dirname(path), 'out.layout'),
        'findText' => 'Not Present',
        'replaceText' => 'Replacement'
      )

      assert_refusal(result, 'layout_no_replacements')
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
