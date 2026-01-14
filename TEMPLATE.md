# Agent Context Template - New Agent Onboarding

---

## Centralized Architecture

This repository uses a centralized agent context system with clear separation of concerns:

### File Structure

```
├── AGENT.md            # Universal repository knowledge (architecture, specs)
├── CLAUDE.md           # Claude Code CLI-specific guidelines
├── GEMINI.md           # Gemini CLI-specific guidelines
├── USER_IDENTITY.md    # User preferences and cognitive style
└── TEMPLATE.md         # THIS FILE: New agent onboarding guide
```

### Design Principles

**Single Source of Truth**: Repository architecture lives in AGENT.md ONLY. Agent-specific guidelines live in [AGENT_NAME].md files. User preferences live in USER_IDENTITY.md ONLY. Zero duplication across files.

**Maintainability**: When repository evolves, update AGENT.md. Agent-specific files remain stable (no architectural details). New features require ONE documentation update, not N updates.

**Scalability**: Adding new agent = create new [AGENT_NAME].md file. No need to modify AGENT.md (universal knowledge stays universal).

**Discoverability**: Uppercase filenames (AGENT.md, CLAUDE.md), root directory location, clear cross-references between files.

### Why This Pattern?

**Problem (Before)**: Each agent had duplicate architectural documentation. Updating repository meant updating N agent files. Drift between agent contexts (inconsistent knowledge). New agents inherited stale info.

**Solution (Now)**: AGENT.md = single source of architectural truth. Agent-specific files = thin customization layer. Update AGENT.md once, all agents benefit. New agents reference AGENT.md, add only agent-specific guidelines.

---

## Creating a New Agent Context File

### Step 1: File Naming and Location

**Filename Convention**: Uppercase, descriptive (CODEX.md, BARD.md, GPT.md)

**Location**: Repository root (same as CLAUDE.md, GEMINI.md)

### Step 2: Use This Skeleton

```markdown
# [AGENT_NAME] - Agent Context

**Core Repository Knowledge**: [AGENT.md](AGENT.md)

**User Preferences**: [USER_IDENTITY.md](USER_IDENTITY.md)

---

## Purpose

This file defines [AGENT_NAME]-specific interaction patterns for the terminal-config repository. All architectural and technical knowledge resides in AGENT.md. This file focuses exclusively on:
- Tool usage conventions
- [Agent-specific capabilities]
- Interaction patterns
- [Other agent-specific guidelines]

---

## Tool Usage Patterns

[Document how this agent should use its available tools]

**Rule 1**: [Describe primary tool usage rule]
- Why: [Rationale]
- Example: [Concrete example]

[Continue with more rules as needed]

---

## Interaction Patterns

[Document how this agent should interact with the user for this repository]

**Guideline 1**: Communication style
- User demands: Professional, formal, concise (see USER_IDENTITY.md)
- [Agent-specific adaptations]

**Guideline 2**: Technical depth
- User expects JFM-level rigor
- [How this agent should handle technical explanations]

[Continue with more guidelines as needed]

---

## Repository-Specific Guidelines

[Document how this agent should work with terminal-config specifically]

**Guideline 1**: Shell configuration changes
- Maintain version manager precedence (see AGENT.md)
- [Agent-specific handling]

**Guideline 2**: [Other repository-specific guidelines]

[Continue with more guidelines as needed]
```

### Step 3: Customize Template

**Sections to Customize**:
1. **Tool Usage Patterns**: Depends on agent's available tools (file ops, code execution, etc.)
2. **Interaction Patterns**: Depends on agent's capabilities (multimodal, code execution, web access, etc.)
3. **Repository-Specific Guidelines**: Depends on repository conventions

**Sections to Keep Generic**:
1. Header with cross-references to AGENT.md and USER_IDENTITY.md
2. Communication style (USER_IDENTITY.md enforces universally)
3. Technical rigor expectations (USER_IDENTITY.md enforces universally)

### Step 4: Add Cross-Reference to AGENT.md

**Update AGENT.md Header** (after USER_IDENTITY, CLAUDE, GEMINI lines):
```markdown
- **[Agent Name] Guidelines**: [[AGENT_NAME].md]([AGENT_NAME].md)
```

**Do NOT Update**: Rest of AGENT.md (architectural knowledge is agent-agnostic).

### Step 5: Test New Context

**Verification Checklist**:
- [ ] New agent can find AGENT.md via cross-reference
- [ ] New agent understands repository architecture from AGENT.md
- [ ] New agent follows USER_IDENTITY.md communication requirements
- [ ] New agent applies agent-specific guidelines from [AGENT_NAME].md
- [ ] No duplication between [AGENT_NAME].md and AGENT.md

---

## Customization Patterns

### Pattern 1: Agent with Limited Tool Access

**Example**: Agent can only read files, not edit them.

```markdown
## Tool Usage Patterns

**Rule 1**: This agent has read-only access.
- Cannot: Edit files, create commits, run scripts
- Can: Read files, analyze code, provide recommendations
- Workflow: Read → Analyze → Recommend changes → User implements
```

### Pattern 2: Agent with Code Execution

**Example**: Agent can run shell scripts, test code.

```markdown
## Tool Usage Patterns

**Rule 1**: Test deployment scripts before recommending.
- Script: `bash_scripts_/deployment_validate.sh`
- Run in sandbox/container if possible
- Report test results to user
```

### Pattern 3: Agent with Web Access

**Example**: Agent can fetch documentation, check package versions.

```markdown
## Tool Usage Patterns

**Rule 1**: Verify external plugin versions before deployment.
- Fetch: https://github.com/zsh-users/zsh-autosuggestions (latest release)
- Fetch: https://github.com/zsh-users/zsh-syntax-highlighting (latest release)
- Compare with installed versions
```

### Pattern 4: Agent with Multimodal Capabilities

**Example**: Agent can display images, diagrams.

```markdown
## Tool Usage Patterns

**Rule 1**: Visualize deployment workflow.
- Generate: Architecture diagrams (extraction → git → deployment)
- Generate: Directory structure trees
- Use: Diagrams to explain complex relationships
```

---

## Key Principles for New Agents

1. **Reference AGENT.md for Architecture**: Never duplicate architectural knowledge
2. **Respect USER_IDENTITY.md**: Enforce communication style (professional, rigorous, zero fluff)
3. **Focus on Agent-Specific Only**: Tool usage, interaction patterns, repository conventions specific to this agent
4. **Maintain Links**: Always cross-reference related documentation
5. **Keep It Concise**: Information density over readability (per user preference)
