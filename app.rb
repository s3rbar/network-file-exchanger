require_relative 'peer_discovery'
require_relative 'transfer_node'

print "Enter your display name: "
username = gets.chomp
tcp_port = 5000 + rand(1000)

node = TransferNode.new(tcp_port)
node.start_server

discovery = PeerDiscovery.new(username, tcp_port)
discovery.start

puts "Listening on TCP port #{tcp_port}..."
puts "Commands: 'peers' (list), 'send <ip> <port> <message>', 'file <ip> <port> <path>', 'exit'"

loop do
  print "> "
  input = gets.chomp.split(' ')
  case input[0]
  when 'peers'
    # Remove inactive peers (> 10s silent)
    now = Time.now
    discovery.peers.delete_if { |_, info| now - info[:last_seen] > 10 }

    puts "--- Discovered Peers ---"
    discovery.peers.each do |_, peer|
      puts "#{peer[:name]} -> #{peer[:ip]}:#{peer[:port]}"
    end
  when 'send'
    _, ip, port, *msg = input
    node.send_payload(ip, port.to_i, username, text: msg.join(' '))
  when 'file'
    _, ip, port, filepath = input
    node.send_payload(ip, port.to_i, username, filename: filepath)
  when 'exit'
    break
  end
end