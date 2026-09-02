# Product artifacts — epics and user stories on disk

## The problem this solves

You hand the agent a document. It comes back with a well-shaped user story and a
clean list of acceptance criteria — in the chat window. Tomorrow the session is
gone, and so is the story.

That was not the agent failing. Until now `skills/requirements/SKILL.md` said, in
so many words, *"this list is the deliverable to send back over chat"*. The
agent had no place to write, so it wrote to chat. **The gap was in the framework,
not in the model.**

Chat is a transport, not a place. A story that lives only there cannot be reread
next week, diffed, linked from a criterion, or handed to whoever has to prove it.

## Where it lives

```
.fw/product/
├── README.md
├── epics/
│   └── checkout.md            boundary and standing decisions across slices
└── criteria/
    ├── checkout-01.md         one user story
    ├── checkout-02.md
    └── checkout-03.md
```

Under `.fw/` because that is already this framework's standing decision for
anything it writes into a repository that is not its own: **one namespace covered
by one global ignore rule**, set by `fw link`. `fw product init` refuses to run
if that rule is missing, rather than quietly dropping product notes into a
client's git history.

## Why the layout is flat

The obvious shape is `epics/checkout/stories/01.md`. It is the wrong one.

An epic already carries a `## Slices` table listing what belongs to it. Nesting
stories inside a per-epic directory records that same relationship a **second**
time, in the directory tree. Two copies of one fact drift: a slice gets renamed
in the table, the folder keeps the old name, and nothing tells you.

One source of truth. The table is it; the filesystem is flat. `fw product hu`
appends the row so the table cannot fall behind.

Stories are not split by repository either — no `backend/` and `frontend/`
subtrees. A story is a unit of business, not of deployment. If it crosses both,
the criterion states which layer proves it; that is the Evidence Gate's job, not
the directory's. Splitting by repo forces you to read two files to understand one
requirement.

## Usage

```bash
fw product init                              # once per project
fw product epic checkout "Split payment"     # start an epic
fw product hu checkout "Reject expired card" # add a story, row appended
fw product                                   # what exists, where each story stands
```

`fw product hu` numbers from the files on disk, never from the table, so a
hand-edited table can never make two stories claim the same id — and a deleted
story never has its number reused. `fw product` exits non-zero when a story has
no epic.

## What goes in a file and what goes in chat

| Situation | Where |
|---|---|
| Story, acceptance criteria, assumptions, evidence map | `criteria/<epic>-NN.md` |
| Gaps, as questions | Chat — a question needs an answer from a person |
| A decision that binds future slices | The epic's Standing decisions table |
| A choice that affects one file | Nowhere. That is a design note, not a decision |

## New projects or maintenance?

**Maintenance benefits more.** On a new project the context is still in your
head, so writing it down feels like duplication. On a codebase you inherited,
that context is exactly what is missing — which is what makes an epic worth its
cost there, not less.

The threshold from `skills/epic/SKILL.md` still governs, and it is honest: *would
a second slice, written a week from now, need to know something decided in the
first one?* If no, there is no epic. A single bug fix does not get one.

## References

- `../skills/requirements/SKILL.md` — the story and the criteria this holds
- `../skills/epic/SKILL.md` — the boundary, and when NOT to write an epic
- `../skills/epic/example.md` — a filled-in epic as the reference shape
- `../bin/fw` — `cmd_product`
