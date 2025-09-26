#!/usr/bin/env node

/**
 * Test script for NVIM_SERVER_ADDRESS auto-detection
 * Usage: NVIM_SERVER_ADDRESS="127.0.0.1:6666" node test_connection.js
 */

import { NeovimDiagnosticsManager } from './dist/enhanced-neovim-manager.js';

async function testConnection() {
  const serverAddress = process.env.NVIM_SERVER_ADDRESS || process.env.NVIM_SOCKET_PATH || '/tmp/nvim';
  
  console.log('🧪 Testing MCP Diagnostics Connection');
  console.log('=' * 50);
  console.log(`Server Address: ${serverAddress}`);
  
  // Parse the address to show what type was detected
  const tcpMatch = serverAddress.match(/^([^:]+):(\d+)$/);
  const portMatch = serverAddress.match(/^(\d+)$/);
  
  if (tcpMatch) {
    console.log(`Detected: TCP connection to ${tcpMatch[1]}:${tcpMatch[2]}`);
  } else if (portMatch) {
    console.log(`Detected: TCP connection to localhost:${portMatch[1]}`);
  } else {
    console.log(`Detected: Socket connection to ${serverAddress}`);
  }
  
  console.log('\n⏳ Attempting connection...');
  
  try {
    const manager = NeovimDiagnosticsManager.getInstance();
    const isHealthy = await manager.healthCheck();
    
    if (isHealthy) {
      console.log('✅ Connection successful!');
      
      // Try to get some basic info
      try {
        const summary = await manager.getDiagnosticSummary();
        console.log(`📊 Diagnostic Summary:`);
        console.log(`   Total: ${summary.total}`);
        console.log(`   Errors: ${summary.errors}`);
        console.log(`   Warnings: ${summary.warnings}`);
        console.log(`   Files: ${summary.files}`);
        
        const bufferStatus = await manager.getBufferStatus();
        const bufferCount = Object.keys(bufferStatus).length;
        console.log(`📄 Buffers loaded: ${bufferCount}`);
        
      } catch (error) {
        console.log('⚠️  Connection works but could not get diagnostics:', error.message);
      }
      
    } else {
      console.log('❌ Connection failed - health check failed');
    }
    
  } catch (error) {
    console.log('❌ Connection error:', error.message);
    console.log('\n💡 Troubleshooting:');
    
    if (tcpMatch || portMatch) {
      const host = tcpMatch ? tcpMatch[1] : 'localhost'; 
      const port = tcpMatch ? tcpMatch[2] : serverAddress;
      console.log(`   1. Make sure Neovim is running with: :lua vim.fn.serverstart('${host}:${port}')`);
      console.log(`   2. Test connection manually: nc ${host} ${port}`);
    } else {
      console.log(`   1. Make sure Neovim is running with: :lua vim.fn.serverstart('${serverAddress}')`);
      console.log(`   2. Check socket exists: ls -la ${serverAddress}`);
    }
  }
}

testConnection().catch(console.error);