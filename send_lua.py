
import sys
import socket
import struct

def send_payload(ip, port, filepath):
    data = open(filepath, "rb").read()
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:        
        sock.connect((ip, int(port)))
        # send size (qword) + <buffer..>
        size = struct.pack("<Q", len(data))   # little endian
        sock.sendall(size + data)
        # recv output
        print(sock.recv(0xffff).decode("latin-1"))

def main():
    
    if len(sys.argv) != 4:
        print("{} <ps-ip> <port> <filepath>".format(sys.argv[0]))
        return

    ip, port, filepath = sys.argv[1:]
    send_payload(ip, port, filepath)


main()
