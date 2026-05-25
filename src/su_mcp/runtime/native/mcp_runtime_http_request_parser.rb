# frozen_string_literal: true

module SU_MCP
  # Parses complete HTTP requests from a nonblocking socket buffer.
  class McpRuntimeHttpRequestParser
    DEFAULT_MAX_HEADER_BYTES = 16 * 1024
    DEFAULT_MAX_BODY_BYTES = 16 * 1024 * 1024

    def initialize(
      max_header_bytes: DEFAULT_MAX_HEADER_BYTES,
      max_body_bytes: DEFAULT_MAX_BODY_BYTES
    )
      @max_header_bytes = max_header_bytes
      @max_body_bytes = max_body_bytes
    end

    def parse(buffer)
      header_end = buffer.index("\r\n\r\n")
      return incomplete_header(buffer) unless header_end
      raise IOError, 'HTTP request headers exceeded limit' if header_end > max_header_bytes

      request_head = buffer.byteslice(0, header_end)
      request_line, headers = parse_request_head(request_head)
      body_result = parse_buffered_body(buffer, header_end + 4, headers)
      return nil unless body_result

      body, request_end = body_result
      buffer.slice!(0, request_end)
      build_request(request_line, headers, body)
    end

    private

    attr_reader :max_header_bytes, :max_body_bytes

    def incomplete_header(buffer)
      raise IOError, 'HTTP request headers exceeded limit' if buffer.bytesize > max_header_bytes

      nil
    end

    def parse_request_head(request_head)
      lines = request_head.split("\r\n")
      request_line = lines.shift.to_s
      headers = lines.each_with_object({}) do |line, result|
        key, value = line.split(':', 2)
        next unless key && value

        result[key.downcase] = value.strip
      end

      [request_line, headers]
    end

    def parse_buffered_body(buffer, body_start, headers)
      if headers['transfer-encoding'].to_s.downcase == 'chunked'
        return parse_buffered_chunked_body(buffer, body_start)
      end

      length = headers.fetch('content-length', '0').to_i
      raise IOError, 'HTTP request body exceeded limit' if length > max_body_bytes

      request_end = body_start + length
      return nil if buffer.bytesize < request_end

      [buffer.byteslice(body_start, length).to_s, request_end]
    end

    def parse_buffered_chunked_body(buffer, body_start)
      chunks = []
      position = body_start

      loop do
        size_line_end = buffer.index("\r\n", position)
        return nil unless size_line_end

        size = buffer.byteslice(position, size_line_end - position).split(';', 2).first.to_i(16)
        position = size_line_end + 2
        return parse_chunked_trailers(buffer, position, chunks) if size.zero?
        return nil if buffer.bytesize < position + size + 2

        chunks << buffer.byteslice(position, size)
        raise IOError, 'HTTP request body exceeded limit' if chunks.sum(&:bytesize) > max_body_bytes

        position += size
        unless buffer.byteslice(position, 2) == "\r\n"
          raise IOError, 'Malformed chunked HTTP request body'
        end

        position += 2
      end
    end

    def parse_chunked_trailers(buffer, position, chunks)
      return [chunks.join, position + 2] if buffer.byteslice(position, 2) == "\r\n"

      trailer_end = buffer.index("\r\n\r\n", position)
      return nil unless trailer_end

      [chunks.join, trailer_end + 4]
    end

    def build_request(request_line, headers, body)
      method, target, _http_version = request_line.strip.split(' ', 3)
      {
        method: method,
        target: target,
        headers: headers,
        body: body
      }
    end
  end
end
