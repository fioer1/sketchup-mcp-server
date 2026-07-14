# frozen_string_literal: true

require 'rexml/document'
require 'zip'
require 'cgi'

module SU_MCP
  module Layout
    # Read-only inspector for SketchUp LayOut .layout archives.
    class LayoutDocumentReader
      class ArchiveUnreadable < StandardError; end
      class PageNotFound < StandardError; end

      SNIPPET_LIMIT = 160

      def initialize(path)
        @path = path
      end

      def document_info
        pages = self.pages
        {
          success: true,
          path: path,
          fileSize: File.size(path),
          pageCount: pages.length,
          pageSize: first_page_size(pages),
          entries: archive_entries_summary,
          warnings: []
        }
      end

      def pages
        @pages ||= page_descriptors.each_with_index.map do |descriptor, index|
          entry_name = descriptor.fetch(:xmlPath)
          xml = read_entry_by_name(entry_name)
          parsed = parse_xml(xml)
          texts = text_snippets(parsed, xml)
          {
            index: index,
            name: descriptor[:name] || page_name(parsed, entry_name, index),
            xmlPath: entry_name,
            bounds: page_bounds(parsed),
            textCount: texts.length
          }
        end
      end

      def inspect_page(page_index: nil, page_name: nil)
        page = page_for(page_index: page_index, page_name: page_name)
        xml = read_entry_by_name(page.fetch(:xmlPath))
        parsed = parse_xml(xml)

        {
          success: true,
          page: page,
          textSnippets: text_snippets(parsed, xml),
          tagCounts: tag_counts(parsed, xml),
          referencedResources: referenced_resources(parsed, xml),
          xmlPath: page.fetch(:xmlPath)
        }
      end

      def find_text(query, case_sensitive: false)
        needle = query.to_s
        matches = pages.filter_map do |page|
          xml = read_entry_by_name(page.fetch(:xmlPath))
          snippet = matching_snippet(xml, needle, case_sensitive: case_sensitive)
          next unless snippet

          { page: page, snippet: snippet }
        end

        {
          success: true,
          query: query,
          caseSensitive: case_sensitive,
          matchCount: matches.length,
          matches: matches
        }
      end

      private

      attr_reader :path

      def archive_entries_summary
        entries = archive_entries
        xml_entries = entries.select { |entry| entry.downcase.end_with?('.xml') }
        {
          count: entries.length,
          xml: xml_entries,
          sample: entries.first(25)
        }
      end

      def first_page_size(pages)
        bounds = pages.map { |page| page[:bounds] }.compact.first
        bounds ||= document_page_size
        return nil unless bounds

        { width: bounds.fetch(:width), height: bounds.fetch(:height), unit: 'inch' }
      end

      def page_descriptors
        refs = document_page_refs
        return refs unless refs.empty?

        page_xml_entry_names.map { |name| { xmlPath: name, name: nil } }
      end

      def page_xml_entry_names
        archive_entries
          .select { |name| name.match?(%r{\Apages/.*\.xml\z}i) }
          .sort
      end

      def document_page_refs
        xml = read_optional_entry('document.xml')
        return [] unless xml

        refs = xml.scan(/<[^>]*pageRef\b[^>]*>/i).filter_map do |tag|
          id = attribute_value(tag, 'r:id') || attribute_value(tag, 'ref')
          name = attribute_value(tag, 'name')
          next unless id

          xml_path = "pages/page#{id.sub(/\Aid/i, '')}.xml"
          next unless archive_entries.include?(xml_path)

          { xmlPath: xml_path, name: name }
        end
        refs.empty? ? [] : refs
      end

      def document_page_size
        xml = read_optional_entry('document.xml')
        return nil unless xml

        tag = xml[/<[^>]*pageInfo\b[^>]*>/i]
        return nil unless tag

        width = float_attribute(tag, 'width')
        height = float_attribute(tag, 'height')
        return nil unless width && height

        { width: width, height: height }
      end

      def read_optional_entry(name)
        read_entry_by_name(name)
      rescue PageNotFound, ArchiveUnreadable
        nil
      end

      def archive_entries
        with_archive { |zip| zip.entries.reject(&:directory?).map(&:name) }
      end

      def read_entry_by_name(name)
        with_archive do |zip|
          entry = zip.find_entry(name)
          raise PageNotFound, "LayOut page XML not found: #{name}" unless entry

          entry.get_input_stream { |stream| stream.read }
        end
      end

      def with_archive
        Zip::File.open(path) { |zip| yield zip }
      rescue Zip::Error, Errno::ENOENT, ArgumentError => e
        raise ArchiveUnreadable, e.message
      end

      def parse_xml(xml)
        REXML::Document.new(xml)
      rescue REXML::ParseException
        nil
      end

      def page_for(page_index:, page_name:)
        if page_index
          page = pages.find { |entry| entry[:index] == page_index.to_i }
          raise PageNotFound, "LayOut page index not found: #{page_index}" unless page

          return page
        end

        page = pages.find { |entry| entry[:name] == page_name }
        raise PageNotFound, "LayOut page not found: #{page_name}" unless page

        page
      end

      def page_name(parsed, entry_name, index)
        root = parsed&.root
        root&.attributes&.[]('name') || File.basename(entry_name, '.xml') || "Page #{index + 1}"
      end

      def page_bounds(parsed)
        root = parsed&.root
        return nil unless root

        width = numeric_attribute(root, 'width')
        height = numeric_attribute(root, 'height')
        return nil unless width && height

        { width: width, height: height }
      end

      def numeric_attribute(element, name)
        value = element.attributes[name]
        return nil if value.nil? || value.empty?

        Float(value)
      rescue ArgumentError
        nil
      end

      def attribute_value(tag, name)
        pattern = /\b#{Regexp.escape(name)}=(["'])(.*?)\1/i
        value = tag.match(pattern)&.[](2)
        value ? CGI.unescapeHTML(value) : nil
      end

      def float_attribute(tag, name)
        value = attribute_value(tag, name)
        value ? Float(value) : nil
      rescue ArgumentError
        nil
      end

      def text_snippets(parsed, xml)
        snippets = []
        if parsed
          parsed.elements.each('//text') do |element|
            snippets << capped(element.text.to_s.strip) unless element.text.to_s.strip.empty?
          end
        end
        snippets = regex_text_snippets(xml) if snippets.empty?
        snippets
      end

      def regex_text_snippets(xml)
        xml.scan(%r{<text[^>]*>(.*?)</text>}im).map do |match|
          capped(strip_xml(match.first))
        end.reject(&:empty?)
      end

      def tag_counts(parsed, xml)
        counts = Hash.new(0)
        if parsed
          parsed.elements.each('//*') { |element| counts[element.name] += 1 }
        else
          xml.scan(/<([A-Za-z][A-Za-z0-9:_-]*)\b/) { |match| counts[match.first] += 1 }
        end
        counts
      end

      def referenced_resources(parsed, xml)
        values = []
        if parsed
          parsed.elements.each('//*') do |element|
            element.attributes.each_attribute do |attribute|
              values << attribute.value if resource_reference?(attribute.value)
            end
          end
        end
        values.concat(xml.scan(/["']([^"']+\.(?:skp|png|jpg|jpeg|pdf|xml))["']/i).flatten)
        values.uniq.sort
      end

      def resource_reference?(value)
        value.to_s.match?(/\.(?:skp|png|jpg|jpeg|pdf|xml)\z/i)
      end

      def matching_snippet(xml, query, case_sensitive:)
        return nil if query.empty?

        haystack = case_sensitive ? xml : xml.downcase
        needle = case_sensitive ? query : query.downcase
        index = haystack.index(needle)
        return nil unless index

        start = [index - 60, 0].max
        capped(strip_xml(xml[start, SNIPPET_LIMIT] || ''))
      end

      def strip_xml(text)
        text.to_s.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
      end

      def capped(text)
        clean = strip_xml(text)
        clean.length > SNIPPET_LIMIT ? "#{clean[0, SNIPPET_LIMIT - 1]}..." : clean
      end
    end
  end
end
