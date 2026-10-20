# FlowForge Community v0.4.0 import bootstrap

This temporary bootstrap commit imports the exact source archive into `flowforge-community/` on the dedicated `flowforge-community-v0.4.0` branch.

The workflow downloads the versioned archive, verifies SHA-256 before extraction, commits the source folder to this branch only, and removes its own bootstrap files. It does not target or update the repository's default branch.

Archive SHA-256: `c3b32ff9c319aaa4450d28b0f89d70965ca2b31d4497810be337da6a343bf7e0`.

If the repository disables GitHub Actions or workflow write permissions, the bootstrap may not run. In that case no source import should be assumed; inspect the workflow run and import the archive manually.
