return {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	root_markers = { "Cargo.toml", "rust-project.json", ".git" },
	settings = {
		["rust-analyzer"] = {
			checkOnSave = { command = "check" },
			procMacro = { enable = false },
			cargo = { buildScripts = { enable = false } },
			diagnostics = { disabled = { "unresolved-proc-macro" } },
			files = {
				excludeDirs = { "target", ".git", "node_modules", ".cargo", ".venv", "venv" },
			},
		},
	},
}
