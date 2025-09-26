import { attach, NeovimClient } from 'neovim';
import * as fs from 'fs/promises';
import * as path from 'path';

export interface Diagnostic {
  bufnr: number;
  lnum: number;
  col: number;
  end_lnum: number;
  end_col: number;
  severity: number;
  message: string;
  source: string;
  code: string | number;
  filename: string;
  severityText: string;
}

export interface DiagnosticSummary {
  total: number;
  errors: number;
  warnings: number;
  info: number;
  hints: number;
  files: number;
  byFile: { [filename: string]: { errors: number; warnings: number; info: number; hints: number } };
  bySource: { [source: string]: number };
}

export interface LSPLocation {
  filename: string;
  lnum: number;
  col: number;
  text: string;
}

export interface DocumentSymbol {
  name: string;
  kind: number;
  kindText: string;
  location: LSPLocation;
  range: {
    start: { line: number; character: number };
    end: { line: number; character: number };
  };
  children?: DocumentSymbol[];
}

export interface WorkspaceSymbol {
  name: string;
  kind: number;
  kindText: string;
  location: LSPLocation;
  containerName?: string;
}

export interface CodeAction {
  title: string;
  kind: string;
  isPreferred?: boolean;
  diagnostics?: Diagnostic[];
  command?: {
    title: string;
    command: string;
    arguments?: any[];
  };
}

export class NeovimConnectionError extends Error {
  constructor(message: string, cause?: Error) {
    super(message);
    this.name = 'NeovimConnectionError';
    this.cause = cause;
  }
}

export class NeovimDiagnosticsManager {
  private static instance: NeovimDiagnosticsManager;
  private nvim: NeovimClient | null = null;
  private connectionPromise: Promise<NeovimClient> | null = null;

  private constructor() {}

  public static getInstance(): NeovimDiagnosticsManager {
    if (!NeovimDiagnosticsManager.instance) {
      NeovimDiagnosticsManager.instance = new NeovimDiagnosticsManager();
    }
    return NeovimDiagnosticsManager.instance;
  }

  private severityToText(severity: number): string {
    switch (severity) {
      case 1: return 'error';
      case 2: return 'warn';
      case 3: return 'info';
      case 4: return 'hint';
      default: return 'unknown';
    }
  }

  private symbolKindToText(kind: number): string {
    const kindMap: { [key: number]: string } = {
      1: 'File', 2: 'Module', 3: 'Namespace', 4: 'Package', 5: 'Class',
      6: 'Method', 7: 'Property', 8: 'Field', 9: 'Constructor', 10: 'Enum',
      11: 'Interface', 12: 'Function', 13: 'Variable', 14: 'Constant', 15: 'String',
      16: 'Number', 17: 'Boolean', 18: 'Array', 19: 'Object', 20: 'Key',
      21: 'Null', 22: 'EnumMember', 23: 'Struct', 24: 'Event', 25: 'Operator',
      26: 'TypeParameter'
    };
    return kindMap[kind] || `Kind${kind}`;
  }

  public async healthCheck(): Promise<boolean> {
    try {
      const nvim = await this.connect();
      await nvim.eval('1'); // Simple test
      return true;
    } catch {
      return false;
    }
  }

  private async connect(): Promise<NeovimClient> {
    if (this.nvim) {
      return this.nvim;
    }

    if (this.connectionPromise) {
      return this.connectionPromise;
    }

    this.connectionPromise = this.establishConnection();
    return this.connectionPromise;
  }

  private async establishConnection(): Promise<NeovimClient> {
    // Support both legacy NVIM_SOCKET_PATH and new NVIM_SERVER_ADDRESS
    const serverAddress = process.env.NVIM_SERVER_ADDRESS || process.env.NVIM_SOCKET_PATH || '/tmp/nvim';
    
    try {
      const connectionConfig = this.parseServerAddress(serverAddress);
      console.error(`Connecting to Neovim ${connectionConfig.type}: ${serverAddress}`);
      
      if (connectionConfig.type === 'tcp') {
        // For TCP connections, use port number if localhost, otherwise use host:port format
        const socketAddress = connectionConfig.host === '127.0.0.1' || connectionConfig.host === 'localhost'
          ? String(connectionConfig.port!)
          : `${connectionConfig.host}:${connectionConfig.port}`;
        this.nvim = attach({ socket: socketAddress });
      } else {
        this.nvim = attach({ socket: connectionConfig.path! });
      }
      
      // Test connection
      await this.nvim.eval('1');
      console.error(`Successfully connected to Neovim via ${connectionConfig.type}`);
      
      return this.nvim;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new NeovimConnectionError(
        `Failed to connect to Neovim at ${serverAddress}. ${this.getConnectionHelp(serverAddress)} Error: ${errorMessage}`,
        error instanceof Error ? error : undefined
      );
    }
  }

  private parseServerAddress(address: string): { type: 'tcp' | 'socket', host?: string, port?: number, path?: string } {
    // Check if it looks like a TCP address (host:port)
    const tcpMatch = address.match(/^([^:]+):(\d+)$/);
    if (tcpMatch) {
      return {
        type: 'tcp',
        host: tcpMatch[1],
        port: parseInt(tcpMatch[2], 10)
      };
    }
    
    // Check if it's a TCP address with protocol
    const tcpProtocolMatch = address.match(/^tcp:\/\/([^:]+):(\d+)$/);
    if (tcpProtocolMatch) {
      return {
        type: 'tcp',
        host: tcpProtocolMatch[1],
        port: parseInt(tcpProtocolMatch[2], 10)
      };
    }
    
    // Check if it's just a port number (assume localhost)
    const portMatch = address.match(/^(\d+)$/);
    if (portMatch) {
      return {
        type: 'tcp',
        host: '127.0.0.1',
        port: parseInt(portMatch[1], 10)
      };
    }
    
    // Otherwise, treat it as a socket path
    return {
      type: 'socket',
      path: address
    };
  }

  private getConnectionHelp(address: string): string {
    const config = this.parseServerAddress(address);
    
    if (config.type === 'tcp') {
      return `Is Neovim running with serverstart? In Neovim: :lua vim.fn.serverstart('${config.host}:${config.port}')`;
    } else {
      return `Is Neovim running with socket server? In Neovim: :lua vim.fn.serverstart('${config.path}')`;
    }
  }

  async ensureFileLoaded(file: string): Promise<boolean> {
    const nvim = await this.connect();
    
    try {
      const result = await nvim.lua(`
        local filepath = "${file}"
        
        -- Get or create buffer for file
        local bufnr = vim.fn.bufnr(filepath, true)
        if bufnr == -1 then
          return { success = false, error = "Failed to create buffer for " .. filepath }
        end
        
        -- Load the file content
        vim.fn.bufload(bufnr)
        
        -- Check if file exists and is readable
        local readable = vim.fn.filereadable(filepath) == 1
        
        return {
          success = true,
          bufnr = bufnr,
          readable = readable,
          loaded = vim.api.nvim_buf_is_loaded(bufnr)
        }
      `);
      
      return (result as any).success;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error loading file into buffer:', errorMessage);
      return false;
    }
  }

  async getBufferStatus(): Promise<{[filename: string]: {bufnr: number, loaded: boolean, modified: boolean}}> {
    const nvim = await this.connect();
    
    try {
      const result = await nvim.lua(`
        local buffers = {}
        
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          local filename = vim.api.nvim_buf_get_name(bufnr)
          if filename ~= "" then
            buffers[filename] = {
              bufnr = bufnr,
              loaded = vim.api.nvim_buf_is_loaded(bufnr),
              modified = vim.api.nvim_buf_get_option(bufnr, 'modified')
            }
          end
        end
        
        return buffers
      `);
      
      return result as any;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting buffer status:', errorMessage);
      return {};
    }
  }

  async getAllDiagnostics(): Promise<Diagnostic[]> {
    // First ensure we have diagnostics from all loaded buffers
    await this.refreshDiagnostics();
    
    const nvim = await this.connect();
    
    try {
      const diagnostics = await nvim.lua(`
        local diagnostics = vim.diagnostic.get()
        local result = {}
        
        for _, diag in ipairs(diagnostics) do
          local bufnr = diag.bufnr
          local filename = vim.api.nvim_buf_get_name(bufnr)
          
          table.insert(result, {
            bufnr = bufnr,
            filename = filename,
            lnum = diag.lnum,
            col = diag.col,
            end_lnum = diag.end_lnum,
            end_col = diag.end_col,
            severity = diag.severity,
            message = diag.message,
            source = diag.source or "",
            code = diag.code or ""
          })
        end
        
        return result
      `);
      
      return (diagnostics as any[]).map(d => ({
        ...d,
        severityText: this.severityToText(d.severity)
      }));
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting diagnostics:', errorMessage);
      return [];
    }
  }

  async getDiagnostics(files?: string[], severity?: string, source?: string): Promise<Diagnostic[]> {
    const nvim = await this.connect();
    
    try {
      let severityLevel: number | undefined;
      if (severity) {
        const severityMap = { 'error': 1, 'warn': 2, 'info': 3, 'hint': 4 };
        severityLevel = severityMap[severity as keyof typeof severityMap];
      }

      const result = await nvim.lua(`
        local files = ...
        local severity_filter = ${severityLevel || 'nil'}
        local source_filter = ${source ? `"${source}"` : 'nil'}
        local result = {}
        
        if files and #files > 0 then
          -- Get diagnostics for specific files
          for _, filepath in ipairs(files) do
            local bufnr = vim.fn.bufnr(filepath, true)
            if bufnr ~= -1 then
              vim.fn.bufload(bufnr)
              
              local diagnostics = vim.diagnostic.get(bufnr)
              
              for _, diag in ipairs(diagnostics) do
                local include = true
                if severity_filter and diag.severity ~= severity_filter then
                  include = false
                end
                if source_filter and (not diag.source or diag.source ~= source_filter) then
                  include = false
                end
                
                if include then
                  table.insert(result, {
                    bufnr = bufnr,
                    filename = filepath,
                    lnum = diag.lnum,
                    col = diag.col,
                    end_lnum = diag.end_lnum,
                    end_col = diag.end_col,
                    severity = diag.severity,
                    message = diag.message,
                    source = diag.source or "",
                    code = diag.code or ""
                  })
                end
              end
            end
          end
        else
          -- Get all diagnostics
          local diagnostics = vim.diagnostic.get()
          
          for _, diag in ipairs(diagnostics) do
            local include = true
            if severity_filter and diag.severity ~= severity_filter then
              include = false
            end
            if source_filter and (not diag.source or diag.source ~= source_filter) then
              include = false
            end
            
            if include then
              local bufnr = diag.bufnr
              local filename = vim.api.nvim_buf_get_name(bufnr)
              
              table.insert(result, {
                bufnr = bufnr,
                filename = filename,
                lnum = diag.lnum,
                col = diag.col,
                end_lnum = diag.end_lnum,
                end_col = diag.end_col,
                severity = diag.severity,
                message = diag.message,
                source = diag.source or "",
                code = diag.code or ""
              })
            end
          end
        end
        
        return result
      `, files);
      
      return (result as any[]).map(d => ({
        ...d,
        severityText: this.severityToText(d.severity)
      }));
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting filtered diagnostics:', errorMessage);
      return [];
    }
  }

  async getDiagnosticSummary(): Promise<DiagnosticSummary> {
    const diagnostics = await this.getAllDiagnostics();
    
    const summary: DiagnosticSummary = {
      total: diagnostics.length,
      errors: 0,
      warnings: 0,
      info: 0,
      hints: 0,
      files: 0,
      byFile: {},
      bySource: {}
    };

    const uniqueFiles = new Set<string>();

    for (const diag of diagnostics) {
      // Count by severity
      switch (diag.severity) {
        case 1: summary.errors++; break;
        case 2: summary.warnings++; break;
        case 3: summary.info++; break;
        case 4: summary.hints++; break;
      }

      // Count by file
      uniqueFiles.add(diag.filename);
      if (!summary.byFile[diag.filename]) {
        summary.byFile[diag.filename] = { errors: 0, warnings: 0, info: 0, hints: 0 };
      }
      switch (diag.severity) {
        case 1: summary.byFile[diag.filename].errors++; break;
        case 2: summary.byFile[diag.filename].warnings++; break;
        case 3: summary.byFile[diag.filename].info++; break;
        case 4: summary.byFile[diag.filename].hints++; break;
      }

      // Count by source
      if (diag.source) {
        summary.bySource[diag.source] = (summary.bySource[diag.source] || 0) + 1;
      }
    }

    summary.files = uniqueFiles.size;
    return summary;
  }

  private async refreshDiagnostics(): Promise<void> {
    const nvim = await this.connect();
    
    try {
      await nvim.lua(`
        -- Refresh diagnostics for all loaded buffers
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufnr) then
            -- Trigger LSP diagnostic refresh if clients are attached
            local clients = vim.lsp.get_active_clients({bufnr = bufnr})
            for _, client in ipairs(clients) do
              if client.server_capabilities.diagnosticProvider then
                vim.lsp.diagnostic.on_publish_diagnostics(nil, {
                  uri = vim.uri_from_bufnr(bufnr),
                  diagnostics = {}
                }, {client_id = client.id})
              end
            end
          end
        end
      `);
    } catch (error) {
      // Ignore errors in diagnostic refresh
    }
  }

  async getHoverInfo(file: string, line: number, col: number): Promise<any> {
    // Ensure file is loaded before getting hover info
    await this.ensureFileLoaded(file);
    
    const nvim = await this.connect();
    
    try {
      const result = await nvim.lua(`
        local filepath = "${file}"
        local line = ${line}
        local col = ${col}
        
        local bufnr = vim.fn.bufnr(filepath, true)
        if bufnr == -1 then
          return { error = "File not found: " .. filepath }
        end
        
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_current_buf(bufnr)
        vim.api.nvim_win_set_cursor(0, {line + 1, col})
        
        local clients = vim.lsp.get_active_clients({bufnr = bufnr})
        if #clients == 0 then
          return { error = "No LSP client attached to buffer" }
        end
        
        local params = vim.lsp.util.make_position_params()
        local results = {}
        
        for _, client in ipairs(clients) do
          if client.server_capabilities.hoverProvider then
            local success, result = pcall(function()
              return client.request_sync('textDocument/hover', params, 5000, bufnr)
            end)
            
            if success and result and result.result then
              table.insert(results, {
                client = client.name,
                hover = result.result
              })
            end
          end
        end
        
        return results
      `);
      
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting hover info:', errorMessage);
      return { error: errorMessage };
    }
  }

  async getDefinitions(file: string, line: number, col: number): Promise<LSPLocation[]> {
    // Ensure file is loaded before getting definitions
    await this.ensureFileLoaded(file);
    
    const nvim = await this.connect();
    
    try {
      const result = await nvim.lua(`
        local filepath = "${file}"
        local line = ${line}
        local col = ${col}
        
        local bufnr = vim.fn.bufnr(filepath, true)
        if bufnr == -1 then
          return { error = "File not found: " .. filepath }
        end
        
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_current_buf(bufnr)
        vim.api.nvim_win_set_cursor(0, {line + 1, col})
        
        local clients = vim.lsp.get_active_clients({bufnr = bufnr})
        if #clients == 0 then
          return { error = "No LSP client attached to buffer" }
        end
        
        local params = vim.lsp.util.make_position_params()
        local results = {}
        
        for _, client in ipairs(clients) do
          if client.server_capabilities.definitionProvider then
            local success, result = pcall(function()
              return client.request_sync('textDocument/definition', params, 5000, bufnr)
            end)
            
            if success and result and result.result then
              for _, location in ipairs(result.result) do
                local uri = location.uri
                local filename = vim.uri_to_fname(uri)
                local range = location.range
                
                table.insert(results, {
                  filename = filename,
                  lnum = range.start.line,
                  col = range.start.character,
                  text = string.format("Definition at %s:%d:%d", 
                    filename, range.start.line + 1, range.start.character + 1)
                })
              end
            end
          end
        end
        
        return results
      `);
      
      return result as LSPLocation[];
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting definitions:', errorMessage);
      return [];
    }
  }

  async getReferences(file: string, line: number, col: number): Promise<LSPLocation[]> {
    // Ensure file is loaded before getting references
    await this.ensureFileLoaded(file);
    
    const nvim = await this.connect();
    
    try {
      const result = await nvim.lua(`
        local filepath = "${file}"
        local line = ${line}
        local col = ${col}
        
        local bufnr = vim.fn.bufnr(filepath, true)
        if bufnr == -1 then
          return { error = "File not found: " .. filepath }
        end
        
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_current_buf(bufnr)
        vim.api.nvim_win_set_cursor(0, {line + 1, col})
        
        local clients = vim.lsp.get_active_clients({bufnr = bufnr})
        if #clients == 0 then
          return { error = "No LSP client attached to buffer" }
        end
        
        local params = vim.lsp.util.make_position_params()
        params.context = { includeDeclaration = true }
        local results = {}
        
        for _, client in ipairs(clients) do
          if client.server_capabilities.referencesProvider then
            local success, result = pcall(function()
              return client.request_sync('textDocument/references', params, 5000, bufnr)
            end)
            
            if success and result and result.result then
              for _, location in ipairs(result.result) do
                local uri = location.uri
                local filename = vim.uri_to_fname(uri)
                local range = location.range
                
                table.insert(results, {
                  filename = filename,
                  lnum = range.start.line,
                  col = range.start.character,
                  text = string.format("Reference at %s:%d:%d", 
                    filename, range.start.line + 1, range.start.character + 1)
                })
              end
            end
          end
        end
        
        return results
      `);
      
      return result as LSPLocation[];
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting references:', errorMessage);
      return [];
    }
  }

  async getDocumentSymbols(file: string): Promise<DocumentSymbol[]> {
    // Ensure file is loaded before getting symbols
    await this.ensureFileLoaded(file);
    
    const nvim = await this.connect();
    
    try {
      const result = await nvim.lua(`
        local filepath = "${file}"
        
        local bufnr = vim.fn.bufnr(filepath, true)
        if bufnr == -1 then
          return { error = "File not found: " .. filepath }
        end
        
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_current_buf(bufnr)
        
        local clients = vim.lsp.get_active_clients({bufnr = bufnr})
        if #clients == 0 then
          return { error = "No LSP client attached to buffer" }
        end
        
        local params = { textDocument = vim.lsp.util.make_text_document_params() }
        local results = {}
        
        for _, client in ipairs(clients) do
          if client.server_capabilities.documentSymbolProvider then
            local success, result = pcall(function()
              return client.request_sync('textDocument/documentSymbol', params, 5000, bufnr)
            end)
            
            if success and result and result.result then
              for _, symbol in ipairs(result.result) do
                local function parse_symbol(sym)
                  local location = {
                    filename = filepath,
                    lnum = sym.range.start.line,
                    col = sym.range.start.character,
                    text = sym.name
                  }
                  
                  local parsed = {
                    name = sym.name,
                    kind = sym.kind,
                    location = location,
                    range = sym.range
                  }
                  
                  if sym.children then
                    parsed.children = {}
                    for _, child in ipairs(sym.children) do
                      table.insert(parsed.children, parse_symbol(child))
                    end
                  end
                  
                  return parsed
                end
                
                table.insert(results, parse_symbol(symbol))
              end
            end
          end
        end
        
        return results
      `);
      
      return (result as any[]).map(s => ({
        ...s,
        kindText: this.symbolKindToText(s.kind)
      }));
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting document symbols:', errorMessage);
      return [];
    }
  }

  async getWorkspaceSymbols(query?: string): Promise<WorkspaceSymbol[]> {
    const nvim = await this.connect();
    
    try {
      const result = await nvim.lua(`
        local query = ${query ? `"${query}"` : '""'}
        
        local clients = vim.lsp.get_active_clients()
        if #clients == 0 then
          return { error = "No LSP clients active" }
        end
        
        local params = { query = query }
        local results = {}
        
        for _, client in ipairs(clients) do
          if client.server_capabilities.workspaceSymbolProvider then
            local success, result = pcall(function()
              return client.request_sync('workspace/symbol', params, 5000)
            end)
            
            if success and result and result.result then
              for _, symbol in ipairs(result.result) do
                local location = {
                  filename = vim.uri_to_fname(symbol.location.uri),
                  lnum = symbol.location.range.start.line,
                  col = symbol.location.range.start.character,
                  text = symbol.name
                }
                
                table.insert(results, {
                  name = symbol.name,
                  kind = symbol.kind,
                  location = location,
                  containerName = symbol.containerName
                })
              end
            end
          end
        end
        
        return results
      `);
      
      return (result as any[]).map(s => ({
        ...s,
        kindText: this.symbolKindToText(s.kind)
      }));
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting workspace symbols:', errorMessage);
      return [];
    }
  }

  async getCodeActions(file: string, line: number, col: number, endLine?: number, endColumn?: number): Promise<CodeAction[]> {
    // Ensure file is loaded before getting code actions
    await this.ensureFileLoaded(file);
    
    const nvim = await this.connect();
    
    try {
      const result = await nvim.lua(`
        local filepath = "${file}"
        local line = ${line}
        local col = ${col}
        local end_line = ${endLine || line}
        local end_col = ${endColumn || col}
        
        local bufnr = vim.fn.bufnr(filepath, true)
        if bufnr == -1 then
          return { error = "File not found: " .. filepath }
        end
        
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_current_buf(bufnr)
        
        local clients = vim.lsp.get_active_clients({bufnr = bufnr})
        if #clients == 0 then
          return { error = "No LSP client attached to buffer" }
        end
        
        local range = {
          start = { line = line, character = col },
          ["end"] = { line = end_line, character = end_col }
        }
        
        local context = {
          diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
        }
        
        local params = {
          textDocument = vim.lsp.util.make_text_document_params(),
          range = range,
          context = context
        }
        
        local results = {}
        
        for _, client in ipairs(clients) do
          if client.server_capabilities.codeActionProvider then
            local success, result = pcall(function()
              return client.request_sync('textDocument/codeAction', params, 5000, bufnr)
            end)
            
            if success and result and result.result then
              for _, action in ipairs(result.result) do
                table.insert(results, {
                  title = action.title,
                  kind = action.kind or "",
                  isPreferred = action.isPreferred,
                  command = action.command,
                  diagnostics = action.diagnostics
                })
              end
            end
          end
        end
        
        return results
      `);
      
      return result as CodeAction[];
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('Error getting code actions:', errorMessage);
      return [];
    }
  }
}
