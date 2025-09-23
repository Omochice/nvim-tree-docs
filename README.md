# nvim-tree-docs

> [!NOTE]
> This plugin requires nvim-treesitter's `main` branch.

Highly configurable documentation generator using treesitter.

This plugin is experimental!

## Setup

nvim-tree-docs is a module for the `nvim-treesitter` plugin. You can install both by doing (vim-plug):

```vim
Plug 'nvim-treesitter/nvim-treesitter', { 'branch': 'main' }
Plug 'Omochice/nvim-tree-docs'
```

You can configure with `setup()` function.

```lua
require("nvim-tree-docs").setup()
```

## Usage

There are two key bindings provided by default:

- `doc_node_at_cursor`: `gdd`
- `doc_all_in_range`: `gdd` (Visual)

If you want disable them, you can configure:

```lua
require("nvim-tree-docs").setup({
  disable_default_mappings = true
})
```

Export them as:

- `require("nvim-tree-docs").doc_node_at_cursor()`
- `require("nvim-tree-docs").doc_all_in_range()`

## Advanced configuration

See [doc/nvim-tree-docs.txt](./doc/nvim-tree-docs.txt).

## Roadmap

- Filetype aliases
- Template marks
- More doc specs
- Doc commands that don't require a treesitter node (jsdoc modules)
- Predefined processors that can be swapped in... (think promptable descriptions?)
