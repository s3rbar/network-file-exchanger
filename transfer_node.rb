require 'socket'
require 'json'

class TransferNode
  def initialize(port)
    @port = port
  end

  # Starts receiving incoming messages/files
  def start_server
    server = TCPServer.new('0.0.0.0', @port)
    Thread.new do
      loop do
        client = server.accept
        Thread.new(client) do |conn|
          header_length = conn.gets.to_i
          header = JSON.parse(conn.read(header_length))

          puts "\n[Received from #{header['from']}]: #{header['filename'] || 'message'}"

          # Read remaining bytes directly or stream to disk
          content = conn.read(header['bytes'])
          if header['filename']
            File.binwrite("received_files/#{header['filename']}", content)
            puts "Saved to received_files/#{header['filename']}"
          else
            puts content
          end

          conn.close
        end
      end
    end
  end

  # Send text or binary file to target peer
  def send_payload(target_ip, target_port, sender_name, filename: nil, text: nil)
    data = filename ? File.binread(filename) : text.to_s
    header = {
      from: sender_name,
      filename: filename ? File.basename(filename) : nil,
      bytes: data.bytesize
    }.to_json

    socket = TCPSocket.new(target_ip, target_port)
    socket.puts(header.bytesize) # Length prefix for header
    socket.write(header)
    socket.write(data)
    socket.close
  end
end