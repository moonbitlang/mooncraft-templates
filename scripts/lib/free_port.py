#!/usr/bin/env python3
import socket


def main():
    sock = socket.socket()
    try:
        sock.bind(("127.0.0.1", 0))
        print(sock.getsockname()[1])
    finally:
        sock.close()


if __name__ == "__main__":
    main()
