import * as net from 'net';
import { Transport, TransportSendOptions } from '@modelcontextprotocol/sdk/shared/transport.js';
import { JSONRPCMessage, RequestId, MessageExtraInfo } from '@modelcontextprotocol/sdk/types.js';

export interface TCPServerTransportOptions {
  port: number;
  host?: string;
  allowMultipleConnections?: boolean;
}

/**
 * TCP Server Transport for MCP
 * Allows MCP servers to accept connections over TCP sockets
 */
export class TCPServerTransport implements Transport {
  private server: net.Server;
  private connections: Set<net.Socket> = new Set();
  private started = false;
  private port: number;
  private host: string;
  private allowMultipleConnections: boolean;

  onclose?: () => void;
  onerror?: (error: Error) => void;
  onmessage?: (message: JSONRPCMessage, extra?: MessageExtraInfo) => void;
  sessionId?: string;
  setProtocolVersion?: (version: string) => void;

  constructor(options: TCPServerTransportOptions) {
    this.port = options.port;
    this.host = options.host || '127.0.0.1';
    this.allowMultipleConnections = options.allowMultipleConnections || false;
    
    this.server = net.createServer();
    this.setupServerHandlers();
  }

  private setupServerHandlers(): void {
    this.server.on('connection', (socket: net.Socket) => {
      console.error(`New TCP connection from ${socket.remoteAddress}:${socket.remotePort}`);
      
      if (!this.allowMultipleConnections && this.connections.size > 0) {
        console.error('Multiple connections not allowed, rejecting new connection');
        socket.end();
        return;
      }

      this.connections.add(socket);
      this.setupSocketHandlers(socket);
    });

    this.server.on('error', (error: Error) => {
      console.error('TCP server error:', error);
      if (this.onerror) {
        this.onerror(error);
      }
    });

    this.server.on('close', () => {
      console.error('TCP server closed');
      if (this.onclose) {
        this.onclose();
      }
    });
  }

  private setupSocketHandlers(socket: net.Socket): void {
    let buffer = '';

    socket.on('data', (data: Buffer) => {
      buffer += data.toString();
      
      // Process complete JSON-RPC messages
      let lines = buffer.split('\n');
      buffer = lines.pop() || ''; // Keep incomplete line in buffer
      
      for (const line of lines) {
        if (line.trim()) {
          try {
            const message = JSON.parse(line.trim()) as JSONRPCMessage;
            if (this.onmessage) {
              this.onmessage(message);
            }
          } catch (error) {
            console.error('Failed to parse JSON-RPC message:', error);
            console.error('Raw message:', line);
          }
        }
      }
    });

    socket.on('close', () => {
      console.error(`TCP connection closed: ${socket.remoteAddress}:${socket.remotePort}`);
      this.connections.delete(socket);
      
      if (this.connections.size === 0 && this.onclose) {
        this.onclose();
      }
    });

    socket.on('error', (error: Error) => {
      console.error('TCP socket error:', error);
      this.connections.delete(socket);
      
      if (this.onerror) {
        this.onerror(error);
      }
    });
  }

  async start(): Promise<void> {
    if (this.started) {
      return;
    }

    return new Promise((resolve, reject) => {
      this.server.listen(this.port, this.host, () => {
        this.started = true;
        console.error(`TCP MCP server listening on ${this.host}:${this.port}`);
        resolve();
      });

      this.server.on('error', reject);
    });
  }

  async send(message: JSONRPCMessage, options?: TransportSendOptions): Promise<void> {
    const messageStr = JSON.stringify(message) + '\n';
    const promises: Promise<void>[] = [];

    for (const socket of this.connections) {
      if (!socket.destroyed) {
        promises.push(
          new Promise((resolve, reject) => {
            socket.write(messageStr, (error) => {
              if (error) {
                reject(error);
              } else {
                resolve();
              }
            });
          })
        );
      }
    }

    if (promises.length === 0) {
      throw new Error('No active TCP connections to send message');
    }

    // Wait for all writes to complete
    await Promise.all(promises);
  }

  async close(): Promise<void> {
    if (!this.started) {
      return;
    }

    // Close all connections
    for (const socket of this.connections) {
      socket.end();
    }
    this.connections.clear();

    return new Promise((resolve) => {
      this.server.close(() => {
        this.started = false;
        resolve();
      });
    });
  }

  getConnectionCount(): number {
    return this.connections.size;
  }

  getServerAddress(): { host: string; port: number } {
    return { host: this.host, port: this.port };
  }
}