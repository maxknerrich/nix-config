I'm Max. You're my Agent. I love to build. I focus on building complex things as simple as possible. I love to find ways to reduce complexity when solving problems.

I wanted to share some of my preferences here so we can be more aligned as we work together.

## Coding preferences - general

- Keep things simple. Channel "yagni" energy unless told otherwise
- Typesaftey is useful, take advantage of it
- Be careful with destructive actions that are not explicitly requested by the user.
- Tests are good. Endless smoke tests, "regression tests" for feature deletions, etc, much less good. Tests should be focused, not slop.
- Comments are a great way to clarify functionality and how code is used. Don't comment every line, but feel free to describe (concisely) how functions are used above function definition, classes, etc.
- Keep comments up to date! When making changes, it's important to keep things in sync.
- Im like functional programming

Before writing code always run through this ladder first:

1. Does this need to exist? → no: skip it (YAGNI)
2. Already in this codebase? → reuse it, don't rewrite
3. Stdlib does it? → use it
4. Native platform feature? → use it
5. Installed dependency? → use it
6. One line? → one line
7. Only then: the minimum that works

## Coding preferences - Typescript focused

- Any is the enemy. Infered types are our friend. Our system should adapt to changes instead of requiring changes everywhere.
- If your TS code looks like a Python developer wrote it, it's bad TS code.
- Avoid one line function that are just casting wrappers
- If not already specified in project, I generally like to use the following tech: Svelte & SvelteKit, Vanilla CSS (no Tailwind), VitePlus as project/test/lint/format runner and package manager, Drizzle with SQLite if a relational database is needed.
- Always target and use new browser features (newest Baseline). If something can be achieved with native browser tech and without JS (without a compromising in UX) use it before implementing you own or installing third party code.
- When building more complex Apps I like to pull in the following tech: EffectTS for robust code (always write code using effectTS, use the effect skill for reference), better-auth for auth and alchemy.run and nix for infrastructure and reproducible environments. Always use EffecTS modules over third-party dependencies (e.g. for schema validation)

## Coding preferences - CSS & HTML focused

- Use CSS Layers and custom properties to make the code more managable and reusable
- Do not hardcode raw color values unless otherwise specified
- Use semantic HTML elements. Prefer `header`, `main`, `section`, `article`, `nav`, `aside`, `footer`, `button`, `form`, `label` over general `div` and `spans`. But do not force a semantic element where a plain container is more accurate
- Accessibility is Required. Use proper labels, `button` for actions und `a` for links
- prefer native html behaviour (`details`, `summary`, `input`, ...)

## Questions are read-only

- A question is a request for an answer not for changes. If the message with common asking phrases orotherwise ask rather than instructs: answer it, do not edit files.
- If the answer is obvious and the change is trivial, still answer first, and offer the change, ask before making it.

## Match ceremony to the task

- Do not spawn subagents for work a single agent can finish in one task.
- When several agents do work in parallel, state file ownership up front to remove collisions

## Blast Radius

- Never touch production live databases, or daily driver build/preview channels, unless explicitly told so. When a task is adjacent to any of them, name what your about to touch before touching it
