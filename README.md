# nvim-lsp-loader

Load your language servers from `.json` or `.lua` files from individual projects. It's a wrapper for [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) and [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer).

There is a [big file](https://github.com/zhang-stephen/dotfiles-on-unix-like/blob/57300d46b26089060868c9926a5a11a6e20f7f63/nvim/lua/modules/lsp/config/languages.lua) to configure my LSP server. I tried to split it to serveral parts but failed, due to [this PR](https://github.com/wbthomason/packer.nvim/pull/192) of  `packer.nvim` is stll in WIP. So I gave up to split this file then, and turned to build a middleware which could load servers from static configuration files.

This plugin is inspired by [coc.nvim](https://github.com/neoclide/coc.nvim) and [nlsp-settings.nvim](https://github.com/tamago324/nlsp-settings.nvim).

### Highlight of Features

- [x] Load default server configurations from specific path, e.g. `~/.config/nvim/languages.json`,
- [x] Find the `.nvim/languages.json` in the root path of porject, or current work directory, and load it,
- [x] highly customized lsp,
- [ ] Support load servers from `.lua` files,
- [ ] Provide user command to load specific server configuration from configuration,
- [ ] More idea is on the road...

### Usage

#### Install

I use [packer.nvim](https://github.com/wbthomason/packer.nvim) to manage my neovim plugins and configurations. But it is supposed to be managed by [paq.nvim]() or [vim-plug](https://github.com/junegunn/vim-plug).

```lua
-- packer.nvim
use 'neovim/nvim-lspconfig'
use 'williamboman/nvim-lsp-installer'
use 'rcarriga/nvim-notify' -- this is an optional dependency

use {
    'zhang-stephen/nvim-lsp-loader'
    after = 'nvim-lspconfig',
    config = function()
        -- DEFAULT CONFIGURATION
        require('nvim-lsp-loader').setup({
            ---@type string | nil where to find the default server configuations, could be nil
            default_config_path = '~/.config/nvim/languages.json',

            ---@type boolean support nested json keys or not, default is false
            nested_json_keys = false,

            ---@type table<string> the patterns to detect the root of project
            root_patterns = { '.git/' },

            ---@type function | nil callback when server is attached to buffer, could be nil
            ---@param client_id integer
            ---@param bufnr integer
            on_attach = nil,

            ---@type function | nil to overwrite the capabilities of server, could be nil
            ---@return table language server capabilities
            make_capabilities = nil,

            ---@type function | nil callback for resolving server configuration, would be invoked before server setup
            ---@param name string the name of language server
            ---@param config table the configuration table of language server
            server_config_cb = nil,

            -- work mode, must be one of {'user-first', 'user-only', 'default-first', 'default-only'}
            mode = 'user-first',
        })
    end
}
```

It shall support to be lazy-loaded if you prefer this way, but this way hasn't been tested.

#### Generate Configuration

User-defined configuration should follow this example.

__NOTICE:__ Comments is not supported in many json decoder.

```js
{
    "languages": {
        // the programming language will be served by its server, its naming is not restricted.
        // but if there are serveral servers for one language, the name shall be unique in all configurations.
        "lua": {
            // name of language server, should be acceptable in nvim-lspconfig/nvim-lsp-installer.
            "name": "sumneko_lua",
            "managed_by": {
                // indicates whether it is installer from nvim-lsp-installer
                // e.g. C/C++ server, ccls or clangd could be installed by package manager, instead of nvim-lsp-installer
                "lsp_installer": true
            },
            // this field will be passed to nvim-lspconfig after resolved, could be null
            // a simple example for neovim plugin developer
            // all available configuration could be found here:
            // https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
            "config": {
                "settings": {
                    "Lua": {
                        "diagnostics": {
                            "globals": [
                                "vim", "packer_plugins"
                            ]
                        },
                        "workspace": {
                            "library": [
                                "$VIMRUNTIME/lua",
                                "$VIMRUNTIME/lua/vim/lsp"
                            ],
                            "maxPreload": 100000,
                            "preloadFileSize": 10000
                        },
                        "telemtry": {
                            "enable": false
                        },
                        "completion": {
                            "keywordSnippet": "Disable",
                            "callSnippet": "Disable"
                        },
                        "runtime": {
                            "version": "Lua 5.1"
                        }
                    }
                },
                // this field will be resolved and overwrotten by lspconfig.util.root_pattern
                // could be null
                "root_dir": [
                    ".git/",
                    "stylua.toml"
                ],
                // this field will be resolved and overwrotten.
                "cmd": [
                    // for the command itself:
                    // the path, relative to lsp server installed path, would be converted to absolute path and passed to nvim-lspconfig,
                    // absolute path would be passed to nvim-lspconfig directly,
                    // it wont't be converted if this server is not managed by nvim-lsp-installer.
                    "sumneko_lua/extension/server/bin/lua-language-server"
                ]
            }
        },
        // other examples for jsonls/clangd
        "json": {
            "name": "jsonls",
            "managed_by": {
                "lsp_installer": true
            }
            "config": {
                "cmd": [
                    // will be converted to absolute path
                    "jsonls/node_modules/.bin/vscode-json-language-server",
                    "--stdio"
                ]
            }
        },
        "c_cpp": {
            "name": "clangd",
            "managed_by": {
                "lsp_installer": false
            },
            "config": {
                "cmd": [
                    // this command will be passed to lspconfig without conversion because it is not managed by nvim-lsp-installer
                    // so it shall be guaranteed that could be found in `$PATH`
                    "clangd",
                    "--log=error",
                    "--background-index",
                    "--clang-tidy",
                    "-j=12",
                    "--enable-config"
                ],
                "root_dir": [
                    ".git/", ".clangd"
                ],
                "single_file_support": true
            }
        }
    }
}
```

Another example from my neovim configuration: [Click Here](https://github.com/zhang-stephen/dotfiles-on-unix-like/blob/master/nvim/languages.json).

#### How the configuration to be loaded?

It will read server configuration from `default_config_path` and `<proj_root>/.config/nvim/languages.json`, which in the root path of project with fixed filename, and mix up the configurations according to the work mode.

+ The configuration from the default will be overloaded by configuration which from `<proj_root>` if the mode were 'user-first',

+ Or the configuration from the `<proj_root>` will be overloaded by configuration from the default if the mode were 'default-first',

+ The configuration from the default will be ignored if the mode were 'user-only',

+ Or configuration from `<proj_root>` will be ignored if the mode is 'default-only'.

Then the servers should be configured automatically.
