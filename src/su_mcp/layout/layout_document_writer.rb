# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'zip'
require_relative 'layout_document_reader'

module SU_MCP
  module Layout
    # Safety-first writer for copied LayOut documents.
    class LayoutDocumentWriter
      class OutputExists < StandardError; end
      class UnsafeOutputPath < StandardError; end
      class NoReplacements < StandardError; end

      def copy_document(source_path:, output_path:, overwrite_output: false)
        validate_output_path!(source_path, output_path, overwrite_output: overwrite_output)
        FileUtils.mkdir_p(File.dirname(output_path))
        FileUtils.cp(source_path, output_path)

        {
          success: true,
          sourcePath: source_path,
          outputPath: output_path,
          operation: 'copied',
          validation: validation_summary(output_path)
        }
      end

      def replace_text(
        source_path:,
        output_path:,
        find_text:,
        replace_text:,
        overwrite_output: false,
        allow_noop: false
      )
        validate_output_path!(source_path, output_path, overwrite_output: overwrite_output)
        FileUtils.mkdir_p(File.dirname(output_path))
        temp_output_path = temporary_output_path(output_path)

        changed_entries = []
        replacement_count = rewrite_archive(
          source_path,
          temp_output_path,
          find_text,
          replace_text,
          changed_entries
        )

        if replacement_count.zero? && !allow_noop
          FileUtils.rm_f(temp_output_path)
          raise NoReplacements, 'No text replacements were found.'
        end

        validation = validation_summary(temp_output_path)
        FileUtils.mv(temp_output_path, output_path, force: true)

        {
          success: true,
          sourcePath: source_path,
          outputPath: output_path,
          operation: 'text_replaced',
          changedEntryCount: changed_entries.length,
          changedEntries: changed_entries,
          replacementCount: replacement_count,
          validation: validation
        }
      ensure
        FileUtils.rm_f(temp_output_path) if temp_output_path && File.exist?(temp_output_path)
      end

      private

      def validate_output_path!(source_path, output_path, overwrite_output:)
        if same_path?(source_path, output_path)
          raise UnsafeOutputPath, 'Output LayOut file must be different from source.'
        end

        return unless File.exist?(output_path) && !overwrite_output

        raise OutputExists, 'Output LayOut file already exists.'
      end

      def same_path?(source_path, output_path)
        File.expand_path(source_path).casecmp?(File.expand_path(output_path))
      end

      def temporary_output_path(output_path)
        directory = File.dirname(output_path)
        basename = File.basename(output_path, '.layout')
        File.join(directory, ".#{basename}.tmp-#{Process.pid}-#{object_id}.layout")
      end

      def rewrite_archive(source_path, output_path, find_text, replace_text, changed_entries)
        replacement_count = 0
        Zip::File.open(source_path) do |input_zip|
          Zip::File.open(output_path, create: true) do |output_zip|
            input_zip.each do |entry|
              next if entry.directory?

              entry.get_input_stream do |stream|
                content = stream.read
                content, count = replace_entry_text(entry.name, content, find_text, replace_text)
                if count.positive?
                  replacement_count += count
                  changed_entries << entry.name
                end
                output_zip.get_output_stream(entry.name) { |out| out.write(content) }
              end
            end
          end
        end
        replacement_count
      end

      def replace_entry_text(entry_name, content, find_text, replace_text)
        return [content, 0] unless entry_name.downcase.end_with?('.xml')
        return [content, 0] if find_text.to_s.empty?

        count = content.scan(find_text).length
        [content.gsub(find_text, replace_text.to_s), count]
      end

      def validation_summary(path)
        info = LayoutDocumentReader.new(path).document_info
        {
          pageCount: info[:pageCount],
          pageSize: info[:pageSize],
          pageNames: LayoutDocumentReader.new(path).pages.map { |page| page[:name] }
        }
      end
    end
  end
end
