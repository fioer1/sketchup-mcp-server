# frozen_string_literal: true

require_relative 'layout_document_reader'

module SU_MCP
  module Layout
    # MCP-facing command wrapper for read-only LayOut document inspection.
    class LayoutCommands
      LAYOUT_EXTENSION = '.layout'

      def layout_get_document_info(args)
        with_reader(args) { |reader| reader.document_info }
      end

      def layout_list_pages(args)
        with_reader(args) do |reader|
          {
            success: true,
            path: normalized_path(args),
            pages: reader.pages
          }
        end
      end

      def layout_inspect_page(args)
        return invalid_page_selector(args) unless page_selector?(args)

        with_reader(args) do |reader|
          reader.inspect_page(
            page_index: args['pageIndex'],
            page_name: args['pageName']
          )
        rescue LayoutDocumentReader::PageNotFound => e
          refusal(
            'layout_page_not_found',
            'LayOut page was not found.',
            args.merge('error' => e.message)
          )
        end
      end

      def layout_find_text(args)
        return missing_query(args) if args['query'].to_s.empty?

        with_reader(args) do |reader|
          reader.find_text(
            args.fetch('query'),
            case_sensitive: args.fetch('caseSensitive', false)
          )
        end
      end

      private

      def with_reader(args)
        validation = validate_path(args)
        return validation unless validation.nil?

        yield LayoutDocumentReader.new(normalized_path(args))
      rescue LayoutDocumentReader::ArchiveUnreadable => e
        refusal(
          'layout_archive_unreadable',
          'LayOut file could not be read as an archive.',
          { path: normalized_path(args), error: e.message }
        )
      end

      def validate_path(args)
        path = normalized_path(args)
        return refusal('missing_path', 'LayOut file path is required.', {}) if path.empty?

        unless File.exist?(path)
          return refusal(
            'layout_file_not_found',
            'LayOut file does not exist.',
            { path: path }
          )
        end

        return nil if File.extname(path).downcase == LAYOUT_EXTENSION

        refusal(
          'invalid_layout_extension',
          'LayOut file path must end with .layout.',
          { path: path, extension: File.extname(path) }
        )
      end

      def normalized_path(args)
        args.fetch('path', '').to_s
      end

      def page_selector?(args)
        args.key?('pageIndex') ^ args.key?('pageName')
      end

      def invalid_page_selector(args)
        refusal(
          'invalid_page_selector',
          'Provide exactly one LayOut page selector: pageIndex or pageName.',
          args
        )
      end

      def missing_query(args)
        refusal(
          'missing_query',
          'Text query is required.',
          args
        )
      end

      def refusal(reason, message, details)
        {
          success: false,
          refusal: {
            reason: reason,
            message: message,
            details: details
          }
        }
      end
    end
  end
end
