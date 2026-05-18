# Agents

This repository uses a four-layer review pipeline. Start here, then read:

- `docs/workflow.md` — how to run the pipeline (owner-facing, PT-BR)
- `.agents/prompts/` — canonical prompts (EN) for Layer 2 and Layer 3 subagents
- `.agents/rules/reporting.md` — `VERDICT:` format and panorama HTML marker (after S3/S4)

Run `make wire-runners` once per clone to symlink runner skill dirs to `.agents/skills/<runner>/`.
