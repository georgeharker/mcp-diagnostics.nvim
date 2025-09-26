#!/usr/bin/env node

/**
 * Test script for MCP TCP Transport
 * Tests basic connectivity and JSON-RPC communication with the TCP server
 */

import net from 'net';

const TCP_HOST = process.env.MCP_TCP_HOST || '127.0.0.1';
const TCP_PORT = parseInt(process.env.MCP_TCP_PORT || '3000');

function createMCPRequest(method, params = {}, id = 1) {
  return {
    jsonrpc: "2.0",
    id,
    method,
    params
  };
}

function sendTCPRequest(host, port, request, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const client = new net.Socket();
    let responseBuffer = '';

    const timeoutId = setTimeout(() => {
      client.destroy();
      reject(new Error(`Request timeout after ${timeout}ms`));
    }, timeout);

    client.connect(port, host, () => {
      console.log(`✅ Connected to TCP server at ${host}:${port}`);
      
      // Send the request
      const message = JSON.stringify(request) + '\n';
      console.log(`📤 Sending: ${message.trim()}`);
      client.write(message);
    });

    client.on('data', (data) => {
      responseBuffer += data.toString();
      
      // Check if we have a complete line (JSON-RPC message)
      const lines = responseBuffer.split('\n');
      
      for (let i = 0; i < lines.length - 1; i++) {
        const line = lines[i].trim();
        if (line) {
          try {
            const response = JSON.parse(line);
            console.log(`📥 Received: ${JSON.stringify(response, null, 2)}`);
            
            clearTimeout(timeoutId);
            client.destroy();
            resolve(response);
            return;
          } catch (error) {
            console.log(`⚠️  Failed to parse response: ${line}`);
          }
        }
      }
      
      // Keep any incomplete line in buffer
      responseBuffer = lines[lines.length - 1];
    });

    client.on('close', () => {
      console.log('🔌 Connection closed');
    });

    client.on('error', (error) => {
      clearTimeout(timeoutId);
      reject(error);
    });
  });
}

async function testTCPConnection() {
  console.log('🧪 Testing MCP TCP Transport');
  console.log('=' * 50);
  console.log(`Target: ${TCP_HOST}:${TCP_PORT}`);
  console.log('');

  try {
    // Test 1: Initialize request
    console.log('📋 Test 1: Initialize request');
    const initRequest = createMCPRequest('initialize', {
      capabilities: { tools: {} },
      clientInfo: { name: 'tcp-test-client', version: '1.0' },
      protocolVersion: '2024-11-05'
    });

    const initResponse = await sendTCPRequest(TCP_HOST, TCP_PORT, initRequest);
    
    if (initResponse.result) {
      console.log('✅ Initialize successful');
      console.log(`   Server: ${initResponse.result.serverInfo?.name || 'Unknown'}`);
      console.log(`   Version: ${initResponse.result.serverInfo?.version || 'Unknown'}`);
    } else if (initResponse.error) {
      console.log(`❌ Initialize failed: ${initResponse.error.message}`);
      return;
    }

    console.log('');

    // Test 2: List tools
    console.log('📋 Test 2: List tools request');
    const toolsRequest = createMCPRequest('tools/list', {}, 2);
    const toolsResponse = await sendTCPRequest(TCP_HOST, TCP_PORT, toolsRequest);
    
    if (toolsResponse.result && toolsResponse.result.tools) {
      console.log('✅ Tools list successful');
      console.log(`   Available tools: ${toolsResponse.result.tools.length}`);
      toolsResponse.result.tools.slice(0, 3).forEach(tool => {
        console.log(`   - ${tool.name}: ${tool.description || 'No description'}`);
      });
      if (toolsResponse.result.tools.length > 3) {
        console.log(`   ... and ${toolsResponse.result.tools.length - 3} more`);
      }
    } else if (toolsResponse.error) {
      console.log(`❌ Tools list failed: ${toolsResponse.error.message}`);
    }

    console.log('');

    // Test 3: List resources
    console.log('📋 Test 3: List resources request');
    const resourcesRequest = createMCPRequest('resources/list', {}, 3);
    const resourcesResponse = await sendTCPRequest(TCP_HOST, TCP_PORT, resourcesRequest);
    
    if (resourcesResponse.result && resourcesResponse.result.resources) {
      console.log('✅ Resources list successful');
      console.log(`   Available resources: ${resourcesResponse.result.resources.length}`);
      resourcesResponse.result.resources.forEach(resource => {
        console.log(`   - ${resource.uri}: ${resource.name || 'No name'}`);
      });
    } else if (resourcesResponse.error) {
      console.log(`❌ Resources list failed: ${resourcesResponse.error.message}`);
    }

    console.log('');
    console.log('🎉 TCP transport test completed successfully!');

  } catch (error) {
    console.log('');
    console.log('❌ TCP connection test failed:', error.message);
    console.log('');
    console.log('💡 Troubleshooting:');
    console.log('   1. Make sure the MCP server is running in TCP mode:');
    console.log(`      npm run start:enhanced:tcp`);
    console.log(`      # or`);
    console.log(`      node dist/enhanced-index.js --tcp-port ${TCP_PORT}`);
    console.log('');
    console.log('   2. Check if the port is already in use:');
    console.log(`      lsof -i :${TCP_PORT}`);
    console.log('');
    console.log('   3. Test basic connectivity:');
    console.log(`      nc ${TCP_HOST} ${TCP_PORT}`);
    
    process.exit(1);
  }
}

// Handle command line arguments
const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) {
  console.log(`
MCP TCP Transport Test

Usage:
  node test_tcp_connection.js                # Test default host:port (127.0.0.1:3000)
  MCP_TCP_HOST=localhost MCP_TCP_PORT=3001 node test_tcp_connection.js

Environment Variables:
  MCP_TCP_HOST    Target host (default: 127.0.0.1)
  MCP_TCP_PORT    Target port (default: 3000)
  `);
  process.exit(0);
}

testTCPConnection().catch(console.error);