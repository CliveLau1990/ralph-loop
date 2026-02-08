# A Ralph Wiggum Loop implementation that works™

Ralph is a long-running AI agent loop. Ralph automates software development tasks by iteratively working through a task list until completion.

This is an implementation that actually works, containing a hackable script so you can configure it to your env and favorite agentic AI CLI. It's set up by default to use Claude Code in a Docker sandbox.

![Ralph Wiggum Loop](https://github.com/user-attachments/assets/052d5290-7e83-4bfb-a6b5-6be761cbe890)

- [Getting Started](#getting-started)
  - [(Optional) Set up code base](#optional-set-up-code-base)
  - [1️⃣ Step 1: Install Ralph](#1️⃣-step-1-install-ralph)
  - [2️⃣ Step 2: Create a PRD + task list](#2️⃣-step-2-create-a-prd--task-list)
  - [3️⃣ Step 3: Set up the agent inside Docker sandbox](#3️⃣-step-3-set-up-the-agent-inside-docker-sandbox)
  - [4️⃣ Step 4: Run Ralph](#4️⃣-step-4-run-ralph)
- [Run the loop](#run-the-loop)
  - [(Optional) Adjusting to your language/framework](#optional-adjusting-to-your-languageframework)
- [How It Works](#how-it-works)
- [How Is This Different from Other Ralphs?](#how-is-this-different-from-other-ralphs)
- [Steering the Agent](#steering-the-agent)
- [Features](#features)
- [Support](#support)
  - [Promise Tags](#promise-tags)
  - [Exit Codes](#exit-codes)
- [Structure](#structure)
- [Skills](#skills)
  - [Available Skills](#available-skills)
  - [Skills Directory Structure](#skills-directory-structure)
- [Reference](#reference)
  - [Playwright configuration](#playwright-configuration)
  - [Vitest configuration](#vitest-configuration)
  - [Running with a different agentic CLI](#running-with-a-different-agentic-cli)
  - [Starting from scratch](#starting-from-scratch)
- [License](#license)

## Getting Started

### (Optional) Set up code base

I recommend using a CLI to bootstrap your project with the necessary tools and dependencies, e.g.:

```bash
npx create-vite@latest src --template react-ts
# or
npx create-next-app@latest src
```

If you must start from a blank slate, which is not recommended, see [Starting from scratch](#starting-from-scratch)

### 1️⃣ Step 1: Install Ralph

Run this in your project's directory to install Ralph.

```bash
npx @pageai/ralph-loop
```

### 2️⃣ Step 2: Create a PRD + task list

Use the `prd-creator` skill to generate a PRD from your requirements.<br/>
Open up Claude Code and prompt it with **your requirements**. Like so:

```
Use the prd-creator skill to help me create a PRD and task list for the below requirements.

An app is already set up with Next.js, Tailwind CSS and TypeScript.

Requirements:

- A SaaS product that helps users manage their finances.
- Target audience: Small business owners and freelancers.
- Core features:
  - Track income and expenses.
  - Create and send invoices.
  - Track payments and receipts.
  - Generate reports and insights.
  - Connect to bank accounts and credit cards.
  - Connect to accounting software.
  - Connect to payment processors.
- Use the shadcn/ui library for components.
- Integrate with Stripe for payments.
- Use Supabase for database.
- You can find env variables in the .env.example file: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, STRIPE_SECRET_KEY, etc. are available in the runtime.

// etc.
```

Pro tips:
- mention libraries and frameworks you want to use
- mention env variables, e.g. for database, 3rd party API keys, etc. Store them in a .env file that you add to **.gitignore**
- *it's fine to write in your own language*

Then follow the Skill's instructions and verify the PRD and then tasks.<br/>
**It is highly recommended that you review individual task requirements before starting the loop. Review EACH TASK INDIVIDUALLY.**

### 3️⃣ Step 3: Set up the agent inside Docker sandbox

Authenticate inside the Docker sandbox before running Ralph. Run:

```bash
docker sandbox run claude .
```

And follow the instructions to log in into Claude Code.

👉 Answer "Yes" to `Bypass Permissions mode`, that's the exact reason why you are using the Docker sandbox.

If you want to use a different agentic CLI, see [Running with a different agentic CLI](#running-with-a-different-agentic-cli).

### 4️⃣ Step 4: Run Ralph

```bash
./ralph.sh -n 50 # Run Ralph Loop with 50 iterations
```

## Run the loop

```bash
# Run the agent loop (default: 10 iterations)
./ralph.sh

# Run with custom iteration limit
./ralph.sh 5
./ralph.sh -n 5
./ralph.sh --max-iterations 5

# Run exactly one iteration
./ralph.sh --once

# Show help
./ralph.sh --help
```

> NB: you might need to run `chmod +x ralph.sh` to make the script executable.

⚠️ The default "mode" is "implementation". Depending on your use case, you might want to change `.agent/PROMPT.md` to a different mode, e.g. "refactor", "review", "test" etc.

⚠️ If you want to use a different language or testing framework, see below.

### (Optional) Adjusting to your language/framework

This script assumes the following are installed:
- [Playwright](https://playwright.dev/) for e2e testing
- [Vitest](https://vitest.dev/) for unit testing
- [TypeScript](https://www.typescriptlang.org/) for type checking
- [ESLint](https://eslint.org/) for linting
- [Prettier](https://prettier.io/) for formatting

If you'd like to use a different language, testing framework etc. please adjust `.agent/PROMPT.md` to reflect your setup, server ports and startup commands etc.

👉 The loop is controlled by this prompt, which will be sent to the agent each iteration.

## How It Works

Each iteration, Ralph will:
1. Find the highest-priority incomplete task from `.agent/tasks.json`
2. Work through the task steps defined in `.agent/tasks/TASK-{ID}.json`
3. Run tests, linting, and type checking
4. Update task status and commit changes
5. Repeat until all tasks pass or max iterations reached

## How Is This Different from Other Ralphs?

This was kept hackable so you can make it your own.<br/>
The script follows the original concepts of the Ralph Wiggum Loop, working with fresh contexts and providing clear verifiable feedback.

It also works generically with any task set.

Besides that:

- it allows you to dump unstructured requirements and have the agent create a PRD and task list for you.
- it uses a task lookup table with individual detailed steps -> more scalable as you get 100s of tasks done.
- it's sandboxed and more secure
- it shows progress and stats so you can keep an eye on what's been done
- it instructs the agent to write and run automated tests and screenshots per task
- it provides observability and traceability of the agent's work, showing a stream of output and capturing full historical logs per iteration

## Steering the Agent

In some cases, you might notice the agent is having trouble, slowed down or struggling to overcome a blocker.

While the loop is running, you can edit the `.agent/STEERING.md` file to add critical work that needs to be done before the loop can continue.

The agent will check this file each iteration and if it finds any critical work, it will skip tasks and complete the critical work first.

## Features

- **PRD generation** - Creates a PRD and task list from requirements
- **Task lookup table generation** - Creates a task lookup table from the PRD
- **Task breakdown + step generation** - Breaks down each task into manageable steps
- **Iteration tracking** - Shows progress through iterations with timing
- **Stream preview** - Shows live output from the Agent
- **Step detection** - Identifies current activity (Thinking, Implementing, Testing, etc.)
- **Screenshot capture** - Captures a screenshot of the current screen
- **Notifications** - Alerts when human input is needed
- **History logging** - Saves clean output from each iteration
- **Timing** - Shows timing metrics for each iteration and total time

## Support

The `ralph.sh` script is designed to be hackable.
It is configured to use Claude Code in a Docker sandbox by default, but with a one-liner change you can change it to use any other agentic AI CLI.

Check the `ralph.sh` script around `# This is the main command loop.` for the main command loop.

> NB: skills are supported by all major agentic AI CLIs via symlinks.

### Promise Tags

Ralph uses semantic tags to communicate status:
- `<promise>COMPLETE</promise>` - All tasks finished successfully
- `<promise>BLOCKED:reason</promise>` - Agent needs human help
- `<promise>DECIDE:question</promise>` - Agent needs a decision

### Exit Codes

| Code | Meaning                        |
| ---- | ------------------------------ |
| 0    | COMPLETE - All tasks finished  |
| 1    | MAX_ITERATIONS - Reached limit |
| 2    | BLOCKED - Needs human help     |
| 3    | DECIDE - Needs human decision  |

## Structure

```
.agent/
├── PROMPT.md           # Prompt sent to Agent each iteration
├── tasks.json          # Task lookup table (required)
├── tasks/              # Individual task specs (TASK-{ID}.json)
├── prd/
│   ├── PRD.md          # Product requirements document
│   └── SUMMARY.md      # Short project overview sent to Agent each iteration
├── logs/
│   └── LOG.md          # Progress log (auto-created)
├── history/            # Iteration output logs
└── skills/             # Shared skills (source of truth)
```

## Skills

Skills are reusable agent capabilities that provide specialized knowledge and workflows. The canonical source is `.agent/skills/`, which is symlinked to multiple agent tool directories for compatibility.

### Available Skills

| Skill                         | Description                                             |
| ----------------------------- | ------------------------------------------------------- |
| `component-refactoring`       | Patterns for splitting and refactoring React components |
| `e2e-tester`                  | End-to-end testing workflows                            |
| `frontend-code-review`        | Code quality and performance review guidelines          |
| `frontend-testing`            | Unit and integration testing patterns                   |
| `prd-creator`                 | Create PRDs and task breakdowns for Ralph               |
| `skill-creator`               | Create new skills                                       |
| `vercel-react-best-practices` | React/Next.js performance patterns                      |
| `web-design-guidelines`       | UI/UX design principles                                 |

### Skills Directory Structure

Skills are symlinked from `.agent/skills/` to multiple locations for cross-tool compatibility:

```
 # Source of truth
.agent/skills/
    ├── component-refactoring/
    ├── e2e-tester/
    ├── frontend-code-review/
    ├── frontend-testing/
    ├── prd-creator/
    ├── skill-creator/
    ├── vercel-react-best-practices/
    └── web-design-guidelines/

# Symlinks -> .agent/skills/*
.agents/skills/
.claude/skills/
.codex/skills/
.cursor/skills/
```

## Reference

### Playwright configuration

If you are using Playwright, here is a recommended configuration:

```typescript:playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  globalTimeout: 30 * 60 * 1000,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  workers: process.env.CI ? 3 : 6,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },


  // NB: only chromium will run in Docker (arm64).
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    }
  ],
});
```

### Vitest configuration

If you are using Vitest, here is a recommended configuration:

```typescript:vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./vitest.setup.ts'],
    include: ['**/*.test.{ts,tsx}'],
    exclude: ['node_modules', '.next', 'tests'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './'),
    },
  },
})

```

And:

```typescript:vitest.setup.ts
import '@testing-library/jest-dom/vitest'
import { vi } from 'vitest'
import React from 'react'

// Mock next/image
vi.mock('next/image', () => ({
  default: ({ src, alt, ...props }: { src: string; alt: string }) => {
    return React.createElement('img', { src, alt, ...props })
  },
}))

// Mock next/link
vi.mock('next/link', () => ({
  default: ({
    children,
    href,
    ...props
  }: {
    children: React.ReactNode
    href: string
  }) => {
    return React.createElement('a', { href, ...props }, children)
  },
}))
```

### Running with a different agentic CLI

If you want to use a different agentic CLI, you can adjust the `ralph.sh` script to reflect your CLI of choice.

Check the `ralph.sh` script around `# This is the main command loop.` for the main command loop.

Replace `docker sandbox run claude . --` with the your favorite CLI. Remember to also update the options after the `--`.

```
docker sandbox run codex . # for Codex CLI
docker sandbox run gemini . # for Gemini CLI
```

Docker currently supports: `claude`, `codex`, `gemini`, `cagent`, `kiro`.
See more in [Docker's docs](https://docs.docker.com/ai/sandboxes/migration/).

### Starting from scratch

For AI to actually verify its implementation and for the loop to work, you need a way to verify it.

To that end, at the minimum you need an end-to-end test framework and a unit test framework.

For example, you can use the following commands to install Playwright and Vitest:

```bash
npm i @playwright/test vitest jsdom typescript eslint prettier -D

# If using React, also recommend installing:
npm i @vitejs/plugin-react @testing-library/dom @testing-library/jest-dom @testing-library/react @testing-library/user-event -D
```

## License

MIT
