import sys
import socket
import struct
import argparse

signals = {
    4: "SIGILL",
    10: "SIGBUS",
    11: "SIGSEGV",
}

COMMAND_MAGIC = struct.pack('<Q', 0xFFFFFFFF)  # Command magic value in byte form (0xFFFFFFFF)
MAGIC_VALUE = struct.pack('<Q', 0x13371337)  # Magic value in byte form (0x13371337)
MAGIC_VALUE_LEN = len(MAGIC_VALUE)
SIGNAL_LEN = 16
MCONTEXT_LEN = 0x100

DISABLE_THREAD = 0
ENABLE_THREAD = 1
DISABLE_SIGNAL_HANDLER = 2
ENABLE_SIGNAL_HANDLER = 3


def print_mcontext(buffer):
    # mcontext_t structure
    fmt = "<QQQQQQQQQQQQQQQQIHHQIHHQQQQQQ"
    
    struct_buf = buffer[:struct.calcsize(fmt)]
    struct_data = struct.unpack(fmt, struct_buf)
    
    regs_name = [
        "onstack", "rdi", "rsi", "rdx", "rcx", 
        "r8", "r9", "rax", "rbx", "rbp", "r10",
        "r11", "r12", "r13", "r14", "r15", "trapno",
        "fs", "gs", "addr", "flags", "es", "ds", "err",
        "rip", "cs", "rflags", "rsp", "ss"
    ]
    
    regs = []
    for name,value in zip(regs_name, struct_data):
        regs.append((name, value))

    print()
    for i in range(1, len(regs), 2):
        print("%5s: %016x  %7s: %016x" % (
            regs[i][0], regs[i][1], regs[i+1][0], regs[i+1][1]
        ))
    print()

def send_command(ip, port, command):    
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:        
        sock.connect((ip, int(port)))
        
        sock.sendall(COMMAND_MAGIC + struct.pack("B", command))
        
        buffer = sock.recv(4096)
        print(buffer.decode("latin-1"), end="")
        
def send_payload(ip, port, filepath):
    data = open(filepath, "rb").read()
    
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:        
        sock.connect((ip, int(port)))
        
        # send size (qword) + <buffer..>
        size = struct.pack("<Q", len(data))   # little endian
        sock.sendall(size + data)
        
        buffer = b""  # Buffer to accumulate partial data
        while True:
            try:
                chunk = sock.recv(4096)
            except Exception as e:
                print(e)
                break
            
            if not chunk:
                break
            
            buffer += chunk  # Add received chunk to buffer

            while True:
                if len(buffer) < MAGIC_VALUE_LEN:  # Not enough data for magic value
                    break
                
                # Search for the magic value
                magic_index = buffer.find(MAGIC_VALUE)
                if magic_index == -1:
                    break  # Magic value not found in current buffer
                
                # Check if we have enough data following the magic value
                if len(buffer) < magic_index + MAGIC_VALUE_LEN + SIGNAL_LEN + MCONTEXT_LEN:  # 8 (magic) + 16 (signal info) + 0x100 (mcontext)
                    break  # Wait for more data
                
                # Extract the 16 bytes following the magic value
                start_index = magic_index + MAGIC_VALUE_LEN
                magic_data = buffer[start_index:start_index + SIGNAL_LEN]

                # Handle the magic_data separately
                crash_code_data, crash_address_data = struct.unpack("<QQ", magic_data)
                
                mcontext_data = buffer[start_index + SIGNAL_LEN : start_index + SIGNAL_LEN + MCONTEXT_LEN]
                
                crash_code = signals.get(crash_code_data, f"Unknown signal code {crash_code_data}")
                crash_address = f"0x{crash_address_data:016x}"

                print(buffer[:magic_index].decode("latin-1"))
                print(f"{crash_code} at {crash_address}")
                print_mcontext(mcontext_data)
                
                buffer = buffer[start_index + SIGNAL_LEN + MCONTEXT_LEN:]
            
            # print leftover data if they are not part of signal handling
            magic_index = buffer.find(MAGIC_VALUE)
            if magic_index == -1:
                print(buffer.decode("latin-1"), end="")
                buffer = b""

def main():
    parser = argparse.ArgumentParser(description='Send payload to specified target')
    group = parser.add_mutually_exclusive_group()
    
    parser.add_argument('ip', help='Target IP address')
    parser.add_argument('port', type=int, help='Target port number')
    group.add_argument('filepath', nargs='?', help='Path to the payload file')
    group.add_argument('--enable-thread', action='store_true', 
                        help='Enable threading for payload execution')
    group.add_argument('--disable-thread', action='store_true', 
                        help='Disable threading for payload execution')
    group.add_argument('--enable-signal-handler', action='store_true', 
                    help='Enable signal handler (print info in case of crash)')
    group.add_argument('--disable-signal-handler', action='store_true', 
                        help='Disable signal handler (print info in case of crash)')
    
    args = parser.parse_args()
    
    if args.disable_thread:
        send_command(args.ip, args.port, DISABLE_THREAD)
    elif args.enable_thread:
        send_command(args.ip, args.port, ENABLE_THREAD)
    elif args.disable_signal_handler:
        send_command(args.ip, args.port, DISABLE_SIGNAL_HANDLER)
    elif args.enable_signal_handler:
        send_command(args.ip, args.port, ENABLE_SIGNAL_HANDLER)
    else:
        send_payload(args.ip, args.port, args.filepath)

if __name__ == "__main__":
    main()