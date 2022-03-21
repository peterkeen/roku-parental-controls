require 'socket'

MULTICAST_ADDR = "239.255.255.250"
BIND_ADDR = "0.0.0.0"
PORT = 1900

receive_thread = Thread.new do
  receive_socket = UDPSocket.new
  membership = IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(BIND_ADDR).hton
  
  receive_socket.setsockopt(:IPPROTO_IP, :IP_ADD_MEMBERSHIP, membership)
  receive_socket.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, 1)
  
  receive_socket.bind(BIND_ADDR, PORT)
  
  loop do
    message, _ = receive_socket.recvfrom(255)
    puts message
  end
end

discover_packet = <<~HERE
M-SEARCH * HTTP/1.1
Host: 239.255.255.250:1900
Man: "ssdp:discover"
ST: roku:ecp
HERE

send_socket = UDPSocket.open
send_socket.setsockopt(:IPPROTO_IP, :IP_MULTICAST_TTL, 1)
send_socket.send(discover_packet, 0, MULTICAST_ADDR, PORT)
send_socket.close

receive_thread.join
