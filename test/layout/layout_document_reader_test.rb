# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require 'zip'
require_relative '../../src/su_mcp/layout/layout_document_reader'

class LayoutDocumentReaderTest < Minitest::Test
  def test_document_info_reports_page_inventory_and_archive_entries
    with_layout_archive do |path|
      info = SU_MCP::Layout::LayoutDocumentReader.new(path).document_info

      assert_equal(true, info[:success])
      assert_equal(path, info[:path])
      assert_equal(2, info[:pageCount])
      assert_equal({ width: 17.0, height: 11.0, unit: 'inch' }, info[:pageSize])
      assert_equal(3, info.dig(:entries, :count))
      assert_includes(info.dig(:entries, :xml), 'pages/page-001.xml')
    end
  end

  def test_pages_preserve_order_and_summarize_text_counts
    with_layout_archive do |path|
      pages = SU_MCP::Layout::LayoutDocumentReader.new(path).pages

      assert_equal(%w[Cover\ Page FLOORPLAN\ (PROPOSED)], pages.map { |page| page[:name] })
      assert_equal([0, 1], pages.map { |page| page[:index] })
      assert_equal('pages/page-002.xml', pages.last[:xmlPath])
      assert_equal(1, pages.last[:textCount])
    end
  end

  def test_pages_use_document_page_refs_for_real_layout_names_and_order
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'document_refs.layout')
      Zip::File.open(path, create: true) do |zip|
        zip.get_output_stream('document.xml') do |io|
          io.write(
            '<layoutDocument><ld:pageManager>' \
            '<ld:pageRef r:id="id56" id="id57" name="Cover Page"/>' \
            '<ld:pageRef r:id="id8" id="id9" name="FLOORPLAN (PROPOSED)"/>' \
            '</ld:pageManager><ld:pageInfo width="17" height="11"/></layoutDocument>'
          )
        end
        zip.get_output_stream('pages/page8.xml') { |io| io.write('<page><text>Kitchen</text></page>') }
        zip.get_output_stream('pages/page56.xml') { |io| io.write('<page><text>Cover</text></page>') }
      end

      reader = SU_MCP::Layout::LayoutDocumentReader.new(path)

      assert_equal(['Cover Page', 'FLOORPLAN (PROPOSED)'], reader.pages.map { |page| page[:name] })
      assert_equal(['pages/page56.xml', 'pages/page8.xml'], reader.pages.map { |page| page[:xmlPath] })
      assert_equal({ width: 17.0, height: 11.0, unit: 'inch' }, reader.document_info[:pageSize])
    end
  end

  def test_inspect_page_by_name_returns_text_tag_counts_and_references
    with_layout_archive do |path|
      page = SU_MCP::Layout::LayoutDocumentReader
             .new(path)
             .inspect_page(page_name: 'FLOORPLAN (PROPOSED)')

      assert_equal(true, page[:success])
      assert_equal(1, page.dig(:page, :index))
      assert_includes(page[:textSnippets], 'Kitchen Note')
      assert_equal(1, page.dig(:tagCounts, 'viewport'))
      assert_includes(page[:referencedResources], 'model.skp')
    end
  end

  def test_find_text_returns_case_insensitive_page_scoped_matches
    with_layout_archive do |path|
      matches = SU_MCP::Layout::LayoutDocumentReader.new(path).find_text('kitchen')

      assert_equal(true, matches[:success])
      assert_equal(1, matches[:matchCount])
      assert_equal(1, matches[:matches].first.dig(:page, :index))
      assert_match(/Kitchen Note/, matches[:matches].first[:snippet])
    end
  end

  def test_invalid_archive_raises_archive_unreadable
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'broken.layout')
      File.write(path, 'not a zip archive')

      assert_raises(SU_MCP::Layout::LayoutDocumentReader::ArchiveUnreadable) do
        SU_MCP::Layout::LayoutDocumentReader.new(path).document_info
      end
    end
  end

  private

  def with_layout_archive
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'sample.layout')
      Zip::File.open(path, create: true) do |zip|
        zip.get_output_stream('pages/page-001.xml') do |io|
          io.write(
            '<page name="Cover Page" width="17" height="11">' \
            '<text>Cover Title</text>' \
            '</page>'
          )
        end
        zip.get_output_stream('pages/page-002.xml') do |io|
          io.write(
            '<page name="FLOORPLAN (PROPOSED)">' \
            '<text>Kitchen Note</text>' \
            '<viewport ref="model.skp"/>' \
            '</page>'
          )
        end
        zip.get_output_stream('resources/model.skp') { |io| io.write('skp placeholder') }
      end

      yield path
    end
  end
end
