# SKILL: Generate ER Diagrams from Prisma Schema (PlantUML)

Purpose
-------
Provide a repeatable workflow for producing high-quality ER diagrams for the rapport using the project's Prisma schema. Diagrams are produced as PlantUML, rendered to PNG/SVG with consistent sizing. Code snippets in the report use syntax highlighting and captured screenshots use consistent dimensions.

Scope
-----
- Workspace-scoped skill for the rapport repository.
- Input: one or more Prisma schema files (commonly `prisma/schema/*.prisma`).
- Output: `diagrams/` PlantUML source files and rendered images suitable for inclusion in the LaTeX report.

Outcomes
--------
- Machine-readable PlantUML ER diagram(s) that reflect the Prisma models, enums and relations.
- Rendered images (SVG preferred, PNG fallback) with consistent dimensions.
- Ready-to-insert Markdown/LaTeX snippets including syntax-highlighted Prisma and PlantUML code blocks.

Step-by-step Workflow
---------------------
1. Locate Prisma schema files
   - Typical paths: `prisma/schema/*.prisma` or `backend/prisma/schema/*.prisma`.
   - If multiple schema files exist, treat each as a module and produce one diagram per logical schema file.

2. Extract models and enums
   - Use `grep` or `sed` to collect `model` and `enum` blocks, or open the file in editor.
   - Validate that the Prisma client has been generated recently; if not, run `npx prisma generate` to ensure types are up-to-date.

3. Map Prisma constructs to PlantUML
   - Models -> PlantUML `entity` blocks.
   - Fields: mark primary keys (PK) by appending `<<PK>>` or styling; mark unique constraints `<<UQ>>`.
   - Types: keep Prisma types as-is in the field list (e.g. `String`, `Int`, `DateTime`).
   - Relations: render as associations with cardinality inferred from `[]` (many) and optional `?` (nullable).
   - Enums: render as `enum` blocks and annotate fields that use them.

4. Produce PlantUML source template
   - Create a `diagrams/prisma-er.puml` file. Basic template:

```plantuml
@startuml prisma-er
skinparam linetype ortho
title Prisma ER diagram — generated

' Entities here
@enduml
```

Insert `entity` blocks like:

```plantuml
entity "User" as User {
  + id : Int <<PK>>
  --
  name : String
  email : String <<UQ>>
}

User ||--o{ Post : "has"
```

5. Rendering commands
   - Prefer SVG for inclusion in LaTeX (scales cleanly). Render with local PlantUML jar or server.
   - Local jar (requires Java):

```bash
plantuml -tsvg diagrams/prisma-er.puml    # renders prisma-er.svg
plantuml -tpng -Ddpi=200 diagrams/prisma-er.puml  # PNG fallback
```

   - Using Docker image:

```bash
docker run --rm -v "$PWD":/workspace plantuml/plantuml:latest -tsvg /workspace/diagrams/prisma-er.puml
```

6. Screenshot guidelines (for UI or rendered images)
   - Use consistent output sizes for screenshots and UI captures: prefer 1200×720 px for full-width images in the report.
   - For diagrams, export SVG. If rasterizing, 1200 px width with 300 DPI produces good print quality.
   - Filenames: `diagrams/prisma-er.svg`, `diagrams/prisma-er.png` (if needed).

7. Code snippets and syntax highlighting
   - Use fenced code blocks in Markdown with language tags for syntax highlighting:

```markdown
```prisma
model User {
  id    Int    @id @default(autoincrement())
  name  String
}
```

```plantuml
@startuml
...plantuml code...
@enduml
```

8. Quality checks and acceptance criteria
   - Diagram contains all `model` names, fields, PKs, unique markers, and relation edges.
   - Enums used by models are represented and annotated.
   - Rendered image is legible at 1200 px width and fits the report layout.
   - Code snippets are copyable and correctly highlighted in the source repo and report.

Decision points / branching logic
--------------------------------
- Multiple schema files: produce one diagram per file and a combined diagram if requested.
- Large schema (many models): generate separate diagrams per bounded context (e.g., `auth`, `order`, `product`).
- Unclear relations: if `@relation` attributes contain explicit `fields`/`references`, use them; otherwise infer cardinality from the field type (`[]` means many).

Iterate
-------
1. Draft: generate PlantUML and a preview SVG.
2. Show preview to reviewer (insert into draft LaTeX or Markdown).
3. Collect feedback: missing models, styling changes (colors, font size), or split into smaller diagrams.
4. Finalize and add rendered files to `diagrams/` and commit.

Example prompts (to use with this skill)
--------------------------------------
- "Generate an ER diagram from `prisma/schema/base.prisma` and output `diagrams/base-er.puml` and `diagrams/base-er.svg`."
- "Render the combined Prisma schema to SVG at 1200px width and include a snippet for the report showing the `User` model." 
- "Split the schema into `auth` and `commerce` diagrams and render both as SVGs."

Troubleshooting
---------------
- If PlantUML fails to render, check Java is installed (`java -version`) or use the Docker image.
- If `listings` in LaTeX complains about languages (e.g. `yaml`), either add the language definition or use `minted` with Pygments (`-shell-escape`).

Files created by this skill
--------------------------
- `diagrams/*.puml` — PlantUML sources
- `diagrams/*.svg` / `diagrams/*.png` — rendered images
- Small helper scripts (optional): `scripts/prisma-to-plantuml.js`

Commit and review checklist
---------------------------
- [ ] `diagrams/*.puml` commited
- [ ] `diagrams/*.svg` commited (or exported to `docs/` as needed)
- [ ] LaTeX snippet added to `rapport.tex` referencing the SVG
- [ ] Code snippets use fenced blocks with language tags

Questions to clarify
--------------------
1. Do you want one combined ER diagram or multiple per domain?
2. Should exported SVGs be committed to the repo or generated during CI?
3. Preferred visual style (colors, compact vs. expanded layout)?

Suggested follow-ups
--------------------
- Add a small script `scripts/prisma-to-plantuml.js` to automate step 2→4.
- Add a CI job to validate PlantUML renders and fail on missing models.

Author
------
Generated for the rapport project — follow this SKILL to produce consistent ER diagrams from Prisma schema.
