#!/usr/bin/env node

/**
 * MCP Diagnostics Extension for Neovim
 * Extends the functionality of mcp-neovim-server with specialized diagnostic and LSP tools
 * 
 * This server complements the existing mcp-neovim-server by providing:
 * - Enhanced diagnostic reporting with filtering and formatting
 * - LSP-specific tools for hover, definitions, references, and symbols
 * - Real-time diagnostic monitoring
 * - Integration with multiple LSP clients
 */

import { McpServer, ResourceTemplate } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { NeovimDiagnosticsManager } from "./neovim-manager.js";
import { TCPServerTransport } from "./tcp-transport.js";
import { spawn } from "child_process";
import { promises as fs } from "fs";
import path from "path";

const server = new McpServer({
  name: "mcp-neovim-diagnostics",
  version: "1.0.0"
});

const diagnosticsManager = NeovimDiagnosticsManager.getInstance();

// Neovim server management
interface NeovimServerConfig {
  address: string;
  headless: boolean;
  configPath?: string;
}

let neovimProcess: any = null;

async function launchNeovimServer(config: NeovimServerConfig): Promise<void> {
  console.error(`Launching Neovim server at address: ${config.address}`);  
  
  const args = ['--listen', config.address];
  
  if (config.headless) {
    args.push('--headless');
  }
  
  if (config.configPath) {
    // Check if config file exists
    try {
      await fs.access(config.configPath);
      args.push('--cmd', `source ${config.configPath}`);
    } catch (error) {
      console.error(`Warning: Config file not found: ${config.configPath}`);
    }
  } else {
    // Try to load the bundled config
    const bundledConfig = path.join(process.cwd(), 'nvim', 'mcp-diagnostics.lua');
    try {
      await fs.access(bundledConfig);
      args.push('--cmd', `lua dofile('${bundledConfig}')`);
      args.push('--cmd', `lua require('mcp-diagnostics').setup({server_address = '${config.address}', auto_start_server = true})`);
    } catch (error) {
      console.error('Warning: Bundled config not found, starting Neovim without MCP config');
    }
  }
  
  console.error(`Starting Neovim with args: nvim ${args.join(' ')}`);
  
  neovimProcess = spawn('nvim', args, {
    stdio: ['ignore', 'pipe', 'pipe'],
    detached: false
  });
  
  neovimProcess.stdout?.on('data', (data: Buffer) => {
    console.error(`Neovim stdout: ${data.toString()}`);
  });
  
  neovimProcess.stderr?.on('data', (data: Buffer) => {
    console.error(`Neovim stderr: ${data.toString()}`);
  });
  
  neovimProcess.on('close', (code: number) => {
    console.error(`Neovim process exited with code ${code}`);
    neovimProcess = null;
  });
  
  neovimProcess.on('error', (error: Error) => {
    console.error(`Failed to start Neovim: ${error.message}`);
    neovimProcess = null;
  });
  
  // Give Neovim a moment to start up
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  if (neovimProcess && !neovimProcess.killed) {
    console.error(`Neovim server started successfully (PID: ${neovimProcess.pid})`);
  } else {
    throw new Error('Failed to start Neovim server');
  }
}

function shutdownNeovimServer(): void {
  if (neovimProcess && !neovimProcess.killed) {
    console.error('Shutting down Neovim server...');
    neovimProcess.kill('SIGTERM');
    neovimProcess = null;
  }
}

// Cleanup on process exit
process.on('SIGINT', () => {
  console.error('Received SIGINT, shutting down...');
  shutdownNeovimServer();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.error('Received SIGTERM, shutting down...');
  shutdownNeovimServer();
  process.exit(0);
});
// Resources for diagnostic data
server.resource(
  "diagnostics",
  new ResourceTemplate("diagnostics://current", { 
    list: () => ({
      resources: [{
        uri: "diagnostics://current",
        mimeType: "application/json", 
        name: "Current Diagnostics",
        description: "All current diagnostics from Neovim buffers"
      }]
    })
  }),
  async (uri) => {
    try {
      const diagnostics = await diagnosticsManager.getAllDiagnostics();
      return {
        contents: [{
          uri: uri.href,
          mimeType: "application/json",
          text: JSON.stringify(diagnostics, null, 2)
        }]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        contents: [{
          uri: uri.href,
          mimeType: "application/json", 
          text: JSON.stringify({ error: `Failed to get diagnostics: ${errorMessage}` }, null, 2)
        }]
      };
    }
  }
);

server.resource(
  "diagnostics-summary",
  new ResourceTemplate("diagnostics://summary", { 
    list: () => ({
      resources: [{
        uri: "diagnostics://summary",
        mimeType: "application/json",
        name: "Diagnostic Summary", 
        description: "Summary of diagnostic counts by severity"
      }]
    })
  }),
  async (uri) => {
    try {
      const summary = await diagnosticsManager.getDiagnosticSummary();
      return {
        contents: [{
          uri: uri.href,
          mimeType: "application/json",
          text: JSON.stringify(summary, null, 2)
        }]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        contents: [{
          uri: uri.href,
          mimeType: "application/json",
          text: JSON.stringify({ error: `Failed to get diagnostic summary: ${errorMessage}` }, null, 2)
        }]
      };
    }
  }
);

// Tools for diagnostic and LSP operations
server.tool(
  "diagnostics_get",
  "Get diagnostics for specified files with optional filtering",
  {
    files: z.array(z.string()).optional().describe("Files to get diagnostics for (all if not specified)"),
    severity: z.enum(["error", "warn", "info", "hint"]).optional().describe("Filter by severity level"),
    source: z.string().optional().describe("Filter by diagnostic source (e.g. 'pylsp', 'eslint')")
  },
  async ({ files, severity, source }) => {
    try {
      const diagnostics = await diagnosticsManager.getDiagnostics(files, severity, source);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(diagnostics, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text", 
            text: JSON.stringify({ error: `Failed to get diagnostics: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

server.tool(
  "diagnostics_summary",
  "Get diagnostic summary with counts by severity and file",
  {},
  async () => {
    try {
      const summary = await diagnosticsManager.getDiagnosticSummary();
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(summary, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to get diagnostic summary: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

server.tool(
  "lsp_hover", 
  "Get LSP hover information for a position in a file",
  {
    file: z.string().describe("File path"),
    line: z.number().describe("Line number (0-based)"), 
    column: z.number().describe("Column number (0-based)")
  },
  async ({ file, line, column }) => {
    try {
      const hoverInfo = await diagnosticsManager.getHoverInfo(file, line, column);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(hoverInfo, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to get hover info: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

server.tool(
  "lsp_definition",
  "Get LSP definition for a symbol at a position",
  {
    file: z.string().describe("File path"),
    line: z.number().describe("Line number (0-based)"),
    column: z.number().describe("Column number (0-based)")
  },
  async ({ file, line, column }) => {
    try {
      const definitions = await diagnosticsManager.getDefinitions(file, line, column);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(definitions, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to get definitions: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

server.tool(
  "lsp_references",
  "Get LSP references for a symbol at a position",
  {
    file: z.string().describe("File path"),
    line: z.number().describe("Line number (0-based)"),
    column: z.number().describe("Column number (0-based)")
  },
  async ({ file, line, column }) => {
    try {
      const references = await diagnosticsManager.getReferences(file, line, column);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(references, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to get references: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

server.tool(
  "lsp_symbols",
  "Get document symbols for a file",
  {
    file: z.string().describe("File path")
  },
  async ({ file }) => {
    try {
      const symbols = await diagnosticsManager.getDocumentSymbols(file);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(symbols, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to get symbols: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

server.tool(
  "lsp_workspace_symbols",
  "Get workspace symbols with optional query",
  {
    query: z.string().optional().describe("Symbol search query")
  },
  async ({ query }) => {
    try {
      const symbols = await diagnosticsManager.getWorkspaceSymbols(query);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(symbols, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to get workspace symbols: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

server.tool(
  "lsp_code_action",
  "Get available code actions for a position or range",
  {
    file: z.string().describe("File path"),
    line: z.number().describe("Line number (0-based)"),
    column: z.number().describe("Column number (0-based)"),
    endLine: z.number().optional().describe("End line number (0-based)"),
    endColumn: z.number().optional().describe("End column number (0-based)")
  },
  async ({ file, line, column, endLine, endColumn }) => {
    try {
      const actions = await diagnosticsManager.getCodeActions(file, line, column, endLine, endColumn);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(actions, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to get code actions: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

// Buffer management tools
server.tool(
  "ensure_files_loaded",
  "Ensure specified files are loaded into Neovim buffers for LSP operations",
  {
    files: z.array(z.string()).describe("Files to load into buffers")
  },
  async ({ files }) => {
    try {
      const results = [];
      for (const file of files) {
        const loaded = await diagnosticsManager.ensureFileLoaded(file);
        results.push({ file, loaded });
      }
      
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ 
              message: "File loading results",
              results 
            }, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to load files: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

server.tool(
  "buffer_status",
  "Get status of all buffers currently loaded in Neovim",
  {},
  async () => {
    try {
      const status = await diagnosticsManager.getBufferStatus();
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(status, null, 2)
          }
        ]
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ error: `Failed to get buffer status: ${errorMessage}` }, null, 2)
          }
        ],
        isError: true
      };
    }
  }
);

// Intelligent prompts for diagnostic workflows
server.prompt(
  "diagnostic_investigation",
  "Guide through systematic diagnostic investigation and error fixing",
  {
    focus_file: z.string().optional().describe("Specific file to focus investigation on"),
    severity_priority: z.enum(["error", "warn", "info", "all"]).optional().describe("Which severity to prioritize")
  },
  async ({ focus_file, severity_priority }) => {
    const summary = await diagnosticsManager.getDiagnosticSummary();
    const diagnostics = await diagnosticsManager.getDiagnostics(
      focus_file ? [focus_file] : undefined,
      severity_priority === "all" ? undefined : severity_priority
    );
    
    const bufferStatus = await diagnosticsManager.getBufferStatus();
    const loadedFiles = Object.keys(bufferStatus);
    
    return {
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `I need help investigating and fixing code issues in my Neovim workspace. Here's the current diagnostic situation:

## Diagnostic Summary
${JSON.stringify(summary, null, 2)}

## Current Issues ${focus_file ? `(focused on ${focus_file})` : ''}
${JSON.stringify(diagnostics.slice(0, 10), null, 2)}${diagnostics.length > 10 ? `\n... and ${diagnostics.length - 10} more` : ''}

## Currently Loaded Files in Neovim
${JSON.stringify(loadedFiles, null, 2)}

Please help me with a systematic approach to:

1. **Prioritize** which errors to fix first based on severity and impact
2. **Investigate** the root causes using LSP tools (hover, definitions, references)  
3. **Navigate** to the problem areas efficiently
4. **Understand** the code context around each issue
5. **Plan** the fixing approach for complex errors

For each significant error, guide me through:
- Using \`lsp_hover\` to understand the symbol at the error location
- Using \`lsp_definition\` to find where problematic symbols are defined
- Using \`lsp_references\` to see how symbols are used elsewhere
- Using \`lsp_code_action\` to find automated fixes

Remember: Files need to be loaded in Neovim buffers for LSP tools to work. Use \`ensure_files_loaded\` if needed.

Start with the most critical issues and guide me step by step.`
          }
        }
      ]
    };
  }
);

server.prompt(
  "lsp_code_exploration", 
  "Guide through LSP-powered code exploration and understanding",
  {
    entry_point: z.string().describe("File path to start exploration from"),
    exploration_goal: z.enum(["understand_structure", "trace_execution", "find_usage", "analyze_dependencies"]).describe("What you want to explore")
  },
  async ({ entry_point, exploration_goal }) => {
    // Ensure the entry point is loaded
    await diagnosticsManager.ensureFileLoaded(entry_point);
    
    const symbols = await diagnosticsManager.getDocumentSymbols(entry_point);
    const bufferStatus = await diagnosticsManager.getBufferStatus();
    
    const explorationGuides = {
      understand_structure: "exploring the overall code structure and relationships",
      trace_execution: "tracing code execution paths and flow",
      find_usage: "finding where symbols and functions are used",
      analyze_dependencies: "analyzing dependencies and imports"
    };
    
    return {
      messages: [
        {
          role: "user", 
          content: {
            type: "text",
            text: `I want to explore and understand code starting from \`${entry_point}\`. My goal is ${explorationGuides[exploration_goal]}.

## Starting Point: ${entry_point}
Document symbols found:
${JSON.stringify(symbols.slice(0, 15), null, 2)}${symbols.length > 15 ? `\n... and ${symbols.length - 15} more symbols` : ''}

## Currently Loaded Files
${JSON.stringify(Object.keys(bufferStatus), null, 2)}

Please guide me through an systematic exploration using LSP tools:

### For Understanding Structure:
1. Use \`lsp_symbols\` to see all symbols in key files
2. Use \`lsp_definition\` on important symbols to understand their implementations
3. Use \`lsp_references\` to see how components connect
4. Use \`lsp_workspace_symbols\` to find related symbols across the project

### For Tracing Execution:
1. Start with entry functions using \`lsp_hover\` for signatures
2. Use \`lsp_definition\` to follow function calls
3. Use \`lsp_references\` to see all call sites
4. Map out the execution flow step by step

### For Finding Usage:
1. Use \`lsp_references\` on symbols to see all usage locations
2. Use \`lsp_workspace_symbols\` to find similar or related symbols
3. Analyze usage patterns and contexts

### For Dependency Analysis:
1. Use \`lsp_definition\` on imports/includes to understand dependencies
2. Use \`lsp_workspace_symbols\` to find all related modules
3. Map out the dependency tree

**Important**: Before exploring any file, ensure it's loaded with \`ensure_files_loaded\`. 

Guide me step by step through this exploration, suggesting specific LSP tool invocations and explaining what to look for in the results.`
          }
        }
      ]
    };
  }
);

server.prompt(
  "error_fixing_workflow",
  "Step-by-step workflow for fixing specific errors using diagnostic and LSP information", 
  {
    error_file: z.string().describe("File containing the error"),
    error_line: z.string().describe("Line number of the error (0-based)"),
    error_message: z.string().optional().describe("The error message if known")
  },
  async ({ error_file, error_line, error_message }) => {
    if (!error_file || !error_line) {
      throw new Error("error_file and error_line are required");
    }
    
    const lineNum = parseInt(error_line, 10);
    if (isNaN(lineNum)) {
      throw new Error("error_line must be a valid number");
    }
    
    await diagnosticsManager.ensureFileLoaded(error_file);
    
    const fileDiagnostics = await diagnosticsManager.getDiagnostics([error_file]);
    const hoverInfo = await diagnosticsManager.getHoverInfo(error_file, lineNum, 0);
    const codeActions = await diagnosticsManager.getCodeActions(error_file, lineNum, 0);
    
    return {
      messages: [
        {
          role: "user",
          content: {
            type: "text", 
            text: `I need to fix an error in \`${error_file}\` at line ${lineNum + 1}${error_message ? `: "${error_message}"` : ''}.

## Current Diagnostics for ${error_file}
${JSON.stringify(fileDiagnostics, null, 2)}

## Context Information
Hover info at error location:
${JSON.stringify(hoverInfo, null, 2)}

## Available Code Actions
${JSON.stringify(codeActions, null, 2)}

Please guide me through a systematic error-fixing approach:

### Step 1: Understanding the Error
- Help me interpret the diagnostic information
- Explain what the error message means in context
- Use \`lsp_hover\` on relevant symbols to understand their types and purposes

### Step 2: Investigating the Root Cause  
- Use \`lsp_definition\` to find where problematic symbols are defined
- Use \`lsp_references\` to see how they're used elsewhere
- Check if this is a pattern throughout the codebase

### Step 3: Planning the Fix
- Evaluate available code actions for automated fixes
- Consider manual fixes if automation isn't available
- Think about potential side effects and test cases needed

### Step 4: Implementation Strategy
- Prioritize fixes that don't break other code
- Suggest using \`lsp_references\` to check impact of changes
- Recommend testing approach

### Step 5: Verification
- How to verify the fix works
- What related diagnostics to check
- How to ensure no new issues were introduced

Start by helping me understand exactly what this error means and what might be causing it.`
          }
        }
      ]
    };
  }
);

server.prompt(
  "workspace_health_check",
  "Comprehensive analysis of workspace code health using diagnostics and LSP",
  {},
  async () => {
    const summary = await diagnosticsManager.getDiagnosticSummary();
    const allDiagnostics = await diagnosticsManager.getAllDiagnostics();
    const bufferStatus = await diagnosticsManager.getBufferStatus();
    
    // Group diagnostics by type and pattern
    const errorPatterns: {[key: string]: number} = {};
    const sourceAnalysis: {[key: string]: {errors: number, warnings: number, total: number}} = {};
    
    for (const diag of allDiagnostics) {
      // Count error patterns
      const pattern = diag.code || diag.message.split(' ').slice(0, 3).join(' ');
      const patternKey = String(pattern);
      errorPatterns[patternKey] = (errorPatterns[patternKey] || 0) + 1;
      
      // Analyze by source
      if (diag.source) {
        const sourceKey = diag.source;
        if (!sourceAnalysis[sourceKey]) {
          sourceAnalysis[sourceKey] = { errors: 0, warnings: 0, total: 0 };
        }
        sourceAnalysis[sourceKey].total++;
        if (diag.severity === 1) sourceAnalysis[sourceKey].errors++;
        if (diag.severity === 2) sourceAnalysis[sourceKey].warnings++;
      }
    }
    
    return {
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `Please analyze the health of my codebase using this comprehensive diagnostic information:

## Overall Health Summary
${JSON.stringify(summary, null, 2)}

## Error Patterns (most common issues)
${JSON.stringify(errorPatterns, null, 2)}

## LSP Source Analysis
${JSON.stringify(sourceAnalysis, null, 2)}

## Buffer Status
Currently loaded files: ${Object.keys(bufferStatus).length}
${JSON.stringify(bufferStatus, null, 2)}

Please provide insights on:

### 🏥 **Health Assessment**
1. Overall code quality score based on diagnostic density
2. Most problematic files that need immediate attention
3. Trending error types that suggest systematic issues
4. LSP coverage - which tools are providing the most value

### 🎯 **Priority Recommendations**
1. Which errors should be fixed first and why
2. Patterns that suggest refactoring opportunities  
3. Files that might benefit from LSP tool exploration
4. Areas where code actions could automate fixes

### 🔧 **Action Plan**
1. Suggest specific diagnostic investigations using our tools
2. Recommend LSP exploration workflows for complex areas
3. Prioritized fixing sequence with rationale
4. Files that should be loaded for deeper analysis

### 🚀 **Improvement Strategies**
1. Patterns to watch out for in future development
2. LSP configuration improvements
3. Preventive measures for common error types

Use the available diagnostic and LSP tools to guide a systematic improvement of the codebase health.`
          }
        }
      ]
    };
  }
);

// Start the server
async function main() {
  // Parse command line arguments for transport mode
  const args = process.argv.slice(2);
  const tcpPortIndex = args.findIndex(arg => arg === '--tcp-port' || arg === '-p');
  const tcpHostIndex = args.findIndex(arg => arg === '--tcp-host' || arg === '-h');
  const launchNvimIndex = args.findIndex(arg => arg === '--launch-nvim');
  const nvimAddressIndex = args.findIndex(arg => arg === '--nvim-address');
  const nvimConfigIndex = args.findIndex(arg => arg === '--nvim-config');
  const nvimHeadlessIndex = args.findIndex(arg => arg === '--nvim-headless');
  const helpIndex = args.findIndex(arg => arg === '--help' || arg === '-help');

  if (helpIndex !== -1) {
    console.log(`
MCP Neovim Diagnostics Server

Usage:
  node index.js                    # Use stdio transport (default)
  node index.js --tcp-port 3000    # Use TCP transport on port 3000
  node index.js -p 3000 -h 0.0.0.0 # TCP on port 3000, all interfaces
  node index.js --launch-nvim      # Launch Neovim server alongside MCP server
  node index.js --launch-nvim --tcp-port 3000 # Launch both with TCP transport

Options:
  --tcp-port, -p <port>    Start TCP server on specified port
  --tcp-host, -h <host>    TCP server host (default: 127.0.0.1)
  --launch-nvim           Launch Neovim server alongside MCP server
  --nvim-address <addr>   Neovim server address (default: /tmp/nvim.sock or TCP based on MCP mode)
  --nvim-config <path>    Path to Neovim config file to load
  --nvim-headless         Launch Neovim in headless mode (default: true)
  --help                   Show this help message

Environment Variables:
  MCP_TCP_PORT            Default TCP port if --tcp-port not specified
  MCP_TCP_HOST            Default TCP host if --tcp-host not specified
  NVIM_SERVER_ADDRESS     Neovim server address (socket path or host:port)
  NVIM_SOCKET_PATH        Legacy Neovim socket path
  NVIM_CONFIG_PATH        Default Neovim config file path
    `);
    process.exit(0);
  }

  // Handle Neovim server launch
  if (launchNvimIndex !== -1) {
    const useTcp = tcpPortIndex !== -1 || process.env.MCP_TCP_PORT;
    const tcpPort = tcpPortIndex !== -1 
      ? parseInt(args[tcpPortIndex + 1]) 
      : parseInt(process.env.MCP_TCP_PORT || '3000');
    const tcpHost = tcpHostIndex !== -1 
      ? args[tcpHostIndex + 1] 
      : process.env.MCP_TCP_HOST || '127.0.0.1';
      
    let nvimAddress;
    if (nvimAddressIndex !== -1) {
      nvimAddress = args[nvimAddressIndex + 1];
    } else if (process.env.NVIM_SERVER_ADDRESS) {
      nvimAddress = process.env.NVIM_SERVER_ADDRESS;
    } else if (useTcp) {
      // If using TCP for MCP, default to TCP for Neovim too but on different port
      nvimAddress = `${tcpHost}:${tcpPort + 1}`;
    } else {
      nvimAddress = process.env.NVIM_SOCKET_PATH || '/tmp/nvim.sock';
    }
    
    const nvimConfig = nvimConfigIndex !== -1 
      ? args[nvimConfigIndex + 1] 
      : process.env.NVIM_CONFIG_PATH;
      
    const headless = nvimHeadlessIndex !== -1 || true; // Default to headless
    
    console.error(`Launching Neovim server before starting MCP server...`);
    console.error(`Neovim address: ${nvimAddress}`);
    console.error(`Headless mode: ${headless}`);
    
    try {
      await launchNeovimServer({
        address: nvimAddress,
        headless,
        configPath: nvimConfig
      });
      
      // Update the diagnostics manager to use the launched Neovim instance
      process.env.NVIM_SERVER_ADDRESS = nvimAddress;
    } catch (error) {
      console.error(`Failed to launch Neovim server: ${error}`);
      process.exit(1);
    }
  }
  let transport;
  
  if (tcpPortIndex !== -1 || process.env.MCP_TCP_PORT) {
    // TCP Transport mode
    const port = tcpPortIndex !== -1 
      ? parseInt(args[tcpPortIndex + 1]) 
      : parseInt(process.env.MCP_TCP_PORT || '3000');
      
    const host = tcpHostIndex !== -1 
      ? args[tcpHostIndex + 1] 
      : process.env.MCP_TCP_HOST || '127.0.0.1';

    if (isNaN(port) || port < 1 || port > 65535) {
      console.error('Error: Invalid TCP port. Must be between 1 and 65535.');
      process.exit(1);
    }

    transport = new TCPServerTransport({
      port,
      host,
      allowMultipleConnections: false // MCP typically expects single connection
    });

    console.error(`Starting MCP server in TCP mode on ${host}:${port}`);
    
  } else {
    // Stdio Transport mode (default)
    transport = new StdioServerTransport();
    console.error("Starting MCP server in stdio mode");
  }

  await server.connect(transport);
  console.error("MCP Neovim Diagnostics Server started successfully");
  
  // For TCP mode, show connection info
  if (transport instanceof TCPServerTransport) {
    const addr = transport.getServerAddress();
    console.error(`TCP server listening on ${addr.host}:${addr.port}`);
    console.error(`Connect with: nc ${addr.host} ${addr.port}`);
    console.error(`Or use in Claude Desktop config: "command": ["nc", "${addr.host}", "${addr.port}"]`);
  }
  
  // Show Neovim server info if launched
  if (neovimProcess && !neovimProcess.killed) {
    const nvimAddr = process.env.NVIM_SERVER_ADDRESS || 'unknown';
    console.error(`Neovim server is running at: ${nvimAddr}`);
    console.error(`Neovim PID: ${neovimProcess.pid}`);
  }
}

main().catch((error) => {
  console.error("Failed to start server:", error);
  process.exit(1);
});
