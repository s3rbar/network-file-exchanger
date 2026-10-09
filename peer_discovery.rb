require 'socket'
require 'json'

class PeerDiscovery
  DISCOVERY_PORT = 45678
  BROADCAST_ADDR = '255.255.255.255'

  attr_reader :peers

  def initialize(username, tcp_port)
    @username = username
    @tcp_port = tcp_port
    @peers = {} # { "ip:port" => { name: "...", last_seen: Time } }
  end

  def start
    Thread.new { listen_for_peers }
    Thread.new { broadcast_presence }
  end

  private

  def broadcast_presence
    socket = UDPSocket.new
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)

    loop do
      message = { name: @username, port: @tcp_port }.to_json
      socket.send(message, 0, BROADCAST_ADDR, DISCOVERY_PORT)
      sleep 3
    end
  end

  def listen_for_peers
    socket = UDPSocket.new
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
    socket.bind('0.0.0.0', DISCOVERY_PORT)

    loop do
      payload, addr_info = socket.recvfrom(1024)
      sender_ip = addr_info[3]
      data = JSON.parse(payload)

      key = "#{sender_ip}:#{data['port']}"
      @peers[key] = {
        name: data['name'],
        ip: sender_ip,
        port: data['port'],
        last_seen: Time.now
      }
    end
  end
end