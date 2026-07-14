# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require 'zip'
require_relative '../../src/su_mcp/layout/layout_document_reader'
require_relative '../../src/su_mcp/layout/layout_document_writer'

class LayoutDocumentWriterTest < Minitest::Test
  BINARY_BYTES = [0, 1, 2, 255, 128, 64].pack('C*')

  def setup
    @writer = SU_MCP::Layout::LayoutDocumentWriter.new
  end

  def test_copy_document_preserves_readable_document_and_binary_resource
    with_layout_archive do |source_path, dir|
      output_path = File.join(dir, 'copy.layout')

      result = @writer.copy_document(source_path: source_path, output_path: output_path)

      assert_equal(true, result[:success])
      assert_equal(source_path, result[:sourcePath])
      assert_equal(output_path, result[:outputPath])
      assert_equal(2, result.dig(:validation, :pageCount))
      assert_equal(BINARY_BYTES, zip_entry_bytes(output_path, 'resources/image.bin'))
    end
  end

  def test_copy_document_refuses_same_source_and_output_path
    with_layout_archive do |source_path, _dir|
      assert_raises(SU_MCP::Layout::LayoutDocumentWriter::UnsafeOutputPath) do
        @writer.copy_document(source_path: source_path, output_path: source_path)
      end
    end
  end

  def test_copy_document_refuses_existing_output_without_overwrite
    with_layout_archive do |source_path, dir|
      output_path = File.join(dir, 'existing.layout')
      File.write(output_path, 'already here')

      assert_raises(SU_MCP::Layout::LayoutDocumentWriter::OutputExists) do
        @writer.copy_document(source_path: source_path, output_path: output_path)
      end
    end
  end

  def test_replace_text_changes_xml_entries_only_and_validates_output
    with_layout_archive do |source_path, dir|
      output_path = File.join(dir, 'replaced.layout')

      result = @writer.replace_text(
        source_path: source_path,
        output_path: output_path,
        find_text: 'PROJECT NAME',
        replace_text: 'MOLINA RESIDENCE'
      )

      assert_equal(true, result[:success])
      assert_equal(1, result[:changedEntryCount])
      assert_equal(2, result[:replacementCount])
      assert_equal(2, result.dig(:validation, :pageCount))
      assert_includes(zip_entry_bytes(output_path, 'pages/page1.xml'), 'MOLINA RESIDENCE')
      assert_equal(BINARY_BYTES, zip_entry_bytes(output_path, 'resources/image.bin'))
    end
  end

  def test_replace_text_refuses_noop_by_default
    with_layout_archive do |source_path, dir|
      output_path = File.join(dir, 'noop.layout')

      assert_raises(SU_MCP::Layout::LayoutDocumentWriter::NoReplacements) do
        @writer.replace_text(
          source_path: source_path,
          output_path: output_path,
          find_text: 'NOT PRESENT',
          replace_text: 'ANYTHING'
        )
      end
    end
  end

  def test_replace_text_noop_with_overwrite_keeps_existing_output
    with_layout_archive do |source_path, dir|
      output_path = File.join(dir, 'existing.layout')
      Zip::File.open(output_path, create: true) do |zip|
        zip.get_output_stream('sentinel.txt') { |io| io.write('keep me') }
      end

      assert_raises(SU_MCP::Layout::LayoutDocumentWriter::NoReplacements) do
        @writer.replace_text(
          source_path: source_path,
          output_path: output_path,
          find_text: 'NOT PRESENT',
          replace_text: 'ANYTHING',
          overwrite_output: true
        )
      end

      assert_equal('keep me', zip_entry_bytes(output_path, 'sentinel.txt'))
    end
  end

  def test_replace_text_allows_noop_when_requested
    with_layout_archive do |source_path, dir|
      output_path = File.join(dir, 'noop.layout')

      result = @writer.replace_text(
        source_path: source_path,
        output_path: output_path,
        find_text: 'NOT PRESENT',
        replace_text: 'ANYTHING',
        allow_noop: true
      )

      assert_equal(true, result[:success])
      assert_equal(0, result[:replacementCount])
      assert_equal(2, result.dig(:validation, :pageCount))
    end
  end

  private

  def with_layout_archive
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'source.layout')
      Zip::File.open(path, create: true) do |zip|
        zip.get_output_stream('document.xml') do |io|
          io.write(
            '<layoutDocument><ld:pageManager>' \
            '<ld:pageRef r:id="id1" name="Cover Page"/>' \
            '<ld:pageRef r:id="id2" name="Inside Page"/>' \
            '</ld:pageManager><ld:pageInfo width="17" height="11"/></layoutDocument>'
          )
        end
        zip.get_output_stream('pages/page1.xml') do |io|
          io.write('<page><text>PROJECT NAME</text><text>PROJECT NAME</text></page>')
        end
        zip.get_output_stream('pages/page2.xml') { |io| io.write('<page><text>Other</text></page>') }
        zip.get_output_stream('resources/image.bin') { |io| io.write(BINARY_BYTES) }
      end

      yield path, dir
    end
  end

  def zip_entry_bytes(path, entry_name)
    Zip::File.open(path) do |zip|
      zip.find_entry(entry_name).get_input_stream { |stream| stream.read }
    end
  end
end
