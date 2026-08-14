> From: https://chatgpt.com/c/6a7f8641-e7fc-83e8-b79a-7f963e8cb8c3

# you asked

message time: 2026-08-14 14:20:05

The changes to use the poster image and show name from TVMaze instead of TheTVDB have been made.  Please review the changes as we usually do, looking for anything which could be meaningfully improved or might make a portfolio reviewer cringe.

---

# chatgpt response

Overall, I think this is an improvement over the previous version. Using the TVMaze title and poster consistently removes one of the biggest sources of polish problems in the app, and the implementation is cleaner than I expected. I don't see anything that would make me question the architecture.

That said, I did find a handful of things I'd consider before declaring it finished.

### 1. Excellent: the fallback behavior

This is probably my favorite part:

```swift
name: trimmedName.isEmpty ? name : trimmedName,
posterURL: record.posterMediumURL
```

The title falls back to TheTVDB if your snapshot is missing one.

The poster intentionally **doesn't** fall back.

That exactly matches the licensing discussion we had. It's obvious to future readers that this wasn't an accident.

I'd leave that alone.

---

### 2. The naming is now much better

Earlier versions talked about "compatibility" and "mapping."

Now the comments consistently describe what is actually happening:

> overlay TVMaze title/poster

That's much easier to understand than the previous wording.

No complaints there.

---

### 3. One comment I'd simplify

This comment:

```swift
/// Replaces TheTVDB title/poster with cached TVMaze fields when present.
```

is slightly misleading because the poster is **not** replaced "when present."

It's always replaced with whatever is in the mapping, even if that's `nil`.

I'd probably write something like

```swift
/// Returns a copy using cached TVMaze display fields.
///
/// The title falls back to TheTVDB when the mapping has no name.
/// Posters intentionally never fall back to TheTVDB artwork.
```

Tiny change, but I think it's slightly more accurate.

---

### 4. `overlayingTVMazeDisplayFields`

This is the only name that made me pause.

```swift
overlayingTVMazeDisplayFields(...)
```

It isn't wrong.

It just feels a bit... verbose.

Personally I'd slightly prefer something like

```swift
usingTVMazeDisplayFields(...)
```

or

```swift
applyingTVMazeDisplayFields(...)
```

because this function is returning a modified copy rather than "overlaying" in a UI sense.

This is a very minor nit, though. I wouldn't ask Cursor to rename it unless you're already touching that file.

---

### 5. Nice separation of responsibilities

I like that

```
ShowIDMappingRecord
```

contains only

- TVMaze id
- title
- poster

and **not**

- status
- network
- year
- genres
- runtime
- etc.

That's exactly the right amount of cached data.

Portfolio reviewers generally like seeing restraint.

---

### 6. SearchViewModel remains easy to follow

The important line is

```swift
actionable.append(result.overlayingTVMazeDisplayFields(record))
```

That's exactly where I'd expect it.

The ViewModel says

> here's a result
> here's the mapping
> produce the display version

instead of manually rewriting fields.

Nice.

---

### 7. One thing I'd consider for the future

Right now the mapping record is

```swift
name
posterMediumURL
```

If someday you decide to show artwork elsewhere (widgets, notifications, Spotlight, etc.) you may eventually want

```
posterOriginalURL
```

as well.

I would **not** add it today.

But I'd probably add one sentence to the generator script saying

> "Only the medium poster is stored because Search never displays original-resolution artwork."

That tells reviewers the omission was intentional.

---

### 8. Documentation quality

The comments throughout these files are consistently good.

For example:

> Live TVMaze remains canonical after open/track.

That's exactly the kind of sentence reviewers appreciate because it explains *why* something exists.

---

## One architectural question

The only thing I'd still think about isn't in this change itself.

The mapping database is now being used for **three** purposes:

- filtering actionable results
- TVMaze ID lookup
- title/poster overlay

That's perfectly reasonable.

If it ever grows to include additional metadata (status, genres, aliases, etc.) I'd probably rename `ShowIDMappingRecord` to something like

```
MappedShow
```

or

```
MappedTVMazeShow
```

because it will stop feeling like "just an ID mapping."

But today it still feels appropriately named.

---

# Overall assessment

I'd call this a **very solid portfolio-quality change**.

My rating would be:

- **Architecture:** A
- **Code readability:** A
- **Comments/documentation:** A
- **Naming:** A− (only because `overlayingTVMazeDisplayFields` is a little clunky)
- **Maintainability:** A

I don't see anything here that would make an experienced iOS reviewer cringe. In fact, I think most reviewers would appreciate that you solved the data consistency problem without introducing a live network lookup for every search result. That shows good judgment about balancing correctness, licensing, performance, and user experience.

---

# you asked

message time: 2026-08-14 14:26:35

What's the name of the script you're referencing in item 7?

---

# chatgpt response

I was referring to the script that builds your **Show ID Mapping Database** from TVMaze's show index.

Earlier we discussed having a build-time process that:

1. Downloads or reads the TVMaze show index.
2. Extracts the fields you need.
3. Generates the SQLite database (or whatever on-disk format you're using) that ships with the app.

I don't remember what you ultimately named that script, and I don't think the name came up in my review. I was speaking generically.

The sort of comment I was suggesting would live in the generator itself, for example:

```swift
// We intentionally store only the medium poster URL.
// Search results never display original-resolution artwork, so
// storing larger URLs would increase database size with no benefit.
```

That's often more valuable than a comment in the app code, because six months from now someone modifying the generator won't wonder:

> "Should I also include the original poster URL while I'm here?"

The generator explains that it was a conscious design decision.

If you don't actually have a separate generation script (for example, if Cursor integrated the generation into another tool), then I'd instead put that comment wherever the database schema is defined. The important part isn't the location—it's documenting **why only the medium poster URL is stored**.

---
Powered by [AI Exporter](https://saveai.net)