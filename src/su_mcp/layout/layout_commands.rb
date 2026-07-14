# frozen_string_literal: true

require_relative 'layout_document_reader'
require_relative 'layout_document_writer'

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

      def layout_copy_document(args)
        validation = validate_source_output_paths(args)
        return validation unless validation.nil?

        writer.copy_document(
          source_path: args.fetch('sourcePath'),
          output_path: args.fetch('outputPath'),
          overwrite_output: args.fetch('overwriteOutput', false)
        )
      rescue LayoutDocumentWriter::UnsafeOutputPath
        refusal(
          'layout_output_same_as_source',
          'Output LayOut file must be different from source.',
          path_details(args)
        )
      rescue LayoutDocumentWriter::OutputExists
        refusal(
          'layout_output_exists',
          'Output LayOut file already exists.',
          path_details(args)
        )
      rescue LayoutDocumentReader::ArchiveUnreadable => e
        archive_unreadable(args.fetch('sourcePath', ''), e.message)
      end

      def layout_replace_text(args)
        validation = validate_source_output_paths(args)
        return validation unless validation.nil?
        return missing_find_text(args) if args['findText'].to_s.empty?

        writer.replace_text(
          source_path: args.fetch('sourcePath'),
          output_path: args.fetch('outputPath'),
          find_text: args.fetch('findText'),
          replace_text: args.fetch('replaceText', ''),
          overwrite_output: args.fetch('overwriteOutput', false),
          allow_noop: args.fetch('allowNoop', false)
        )
      rescue LayoutDocumentWriter::UnsafeOutputPath
        refusal(
          'layout_output_same_as_source',
          'Output LayOut file must be different from source.',
          path_details(args)
        )
      rescue LayoutDocumentWriter::OutputExists
        refusal(
          'layout_output_exists',
          'Output LayOut file already exists.',
          path_details(args)
        )
      rescue LayoutDocumentWriter::NoReplacements
        refusal(
          'layout_no_replacements',
          'No text replacements were found.',
          path_details(args).merge(findText: args['findText'])
        )
      rescue LayoutDocumentReader::ArchiveUnreadable => e
        archive_unreadable(args.fetch('sourcePath', ''), e.message)
      end

      def layout_validate_document(args)
        validation = validate_layout_path(args, field: 'path', missing_reason: 'missing_layout_path')
        return validation unless validation.nil?

        info = LayoutDocumentReader.new(args.fetch('path')).document_info
        pages = LayoutDocumentReader.new(args.fetch('path')).pages
        {
          success: true,
          path: args.fetch('path'),
          pageCount: info[:pageCount],
          pageSize: info[:pageSize],
          pageNames: pages.map { |page| page[:name] }
        }
      rescue LayoutDocumentReader::ArchiveUnreadable => e
        archive_unreadable(args.fetch('path', ''), e.message)
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

      def writer
        @writer ||= LayoutDocumentWriter.new
      end

      def validate_path(args)
        path = normalized_path(args)
        return refusal('missing_path', 'LayOut file path is required.', {}) if path.empty?

        file_validation = validate_existing_file(path)
        return file_validation unless file_validation.nil?

        validate_layout_extension(path)
      end

      def validate_source_output_paths(args)
        output_path = args.fetch('outputPath', '').to_s
        return refusal('missing_output_path', 'Output LayOut file path is required.', {}) if output_path.empty?

        source_validation = validate_layout_path(
          args,
          field: 'sourcePath',
          missing_reason: 'missing_source_path'
        )
        return source_validation unless source_validation.nil?

        validate_layout_extension(output_path)
      end

      def validate_layout_path(args, field:, missing_reason:)
        path = args.fetch(field, '').to_s
        return refusal(missing_reason, 'LayOut file path is required.', {}) if path.empty?

        file_validation = validate_existing_file(path)
        return file_validation unless file_validation.nil?

        validate_layout_extension(path)
      end

      def validate_existing_file(path)
        return nil if File.exist?(path)

        refusal(
          'layout_file_not_found',
          'LayOut file does not exist.',
          { path: path }
        )
      end

      def validate_layout_extension(path)
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

      def missing_find_text(args)
        refusal(
          'missing_find_text',
          'findText is required.',
          args
        )
      end

      def archive_unreadable(path, error)
        refusal(
          'layout_archive_unreadable',
          'LayOut file could not be read as an archive.',
          { path: path, error: error }
        )
      end

      def path_details(args)
        {
          sourcePath: args['sourcePath'],
          outputPath: args['outputPath']
        }
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
