# Search improvements comparison

## User

Please read the search improvements documented in "Release Readiness.md" and tell me if there is anything there that TVMaze's search doesn't already do.

I've read the search improvements. Let me check how the app currently uses TVMaze search and verify TVMaze's documented search behavior.

Let me look at the current search client implementation to see exactly how the app queries TVMaze.

I've read the search improvements in `Release Readiness.md` and cross-checked them against how the app currently queries TVMaze and what TVMaze's search engine actually does.

## How the app queries TVMaze today

The app hits `/search/shows?q=` and returns results in TVMaze's own order, with no client-side normalization or re-ranking:

```40:48:NextSeason/Services/TVMazeClient.swift
    func searchShows(matching query: String) async throws -> [Show] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(url: baseURL.appending(path: "search/shows"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        let results: [ShowSearchResultData] = try await get(components)
        return results.map { $0.show.toDomain() }
    }
```

TVMaze's `/search/shows` is backed by Elasticsearch with a fuzzy algorithm (fuzziness 2), and its relevance score combines fuzzy closeness + popularity weight + exact-match boost, including matches against AKA/alternate names.

## Improvement-by-improvement assessment

| Documented improvement | Does TVMaze already do it? |
|---|---|
| **Ignore punctuation differences** | Mostly yes. Elasticsearch's analyzer tokenizes and strips most punctuation, so `halt and catch fire` ≈ `halt-and-catch-fire`. |
| **Improve result ranking** | Partly. TVMaze already ranks by relevance (fuzzy + popularity + exact-match). What it *can't* do is rank for *your app's purpose* — e.g. surfacing shows that actually have an upcoming season. That's genuinely app-side. |
| **Handle partial title searches** | Yes. Partial matches are supported and scored (shorter matching titles score higher). |
| **Improve matching of alternate show names** | Yes. TVMaze searches AKA names already (AKA matches just score lower than main-title matches). |
| **Ignore common articles ("The", "A")** | Largely covered indirectly. The standard analyzer does *not* strip English stopwords, so "The" isn't explicitly dropped — but because partial matching works, searching `office` still returns `The Office`. Not a true article-removal feature. |
| **Handle common abbreviations** | No. Fuzziness 2 only fixes small typos (edit distance), not acronyms/abbreviations like `GoT` → Game of Thrones or `SVU`. The only abbreviations that work are ones registered as AKA names. This is the clearest real gap. |

## Bottom line

Four of the six are **already substantially handled by TVMaze** and would mostly be wasted effort to reimplement client-side:

- Ignore punctuation differences
- Handle partial title searches
- Improve matching of alternate show names
- Basic result ranking (relevancy + popularity)

Only two represent real, app-side opportunities:

1. **Handle common abbreviations / acronyms** — TVMaze genuinely doesn't expand these, so a small local synonym/alias map (`GoT` → "Game of Thrones", etc.) would add value.
2. **App-purpose ranking** — not "better relevance" (TVMaze does that), but re-ordering or annotating results around *NextSeason's* job, e.g. de-emphasizing ended shows or highlighting ones with a known/upcoming next season.

The "ignore articles" item is a minor edge case that's mostly already covered by partial matching, so it's low value.

One caveat worth flagging for the doc: the success criterion is *"most users can find a show without multiple attempts."* Since TVMaze already covers most of this list, the realistic remaining wins are abbreviations and app-specific ranking — you may want to validate during beta whether search is actually a pain point before investing here at all.

I haven't changed any code — this was a research/comparison request. Want me to update `Release Readiness.md` to reflect which of these TVMaze already handles, or prototype the abbreviation alias map?

## User

Yes

## Assistant

Your "Yes" covers an either/or question, so I want to confirm scope before changing anything.

I'll make a small, focused edit to the "Search Quality Improvements" section of `Release Readiness.md`, annotating each potential improvement with whether TVMaze already handles it and adding a brief note so the remaining real work is clear. I won't touch other sections.

Done. I updated only the **Search Quality Improvements** section of `Documentation/MVP/Release Readiness.md`.

What changed:
- Added a **TVMaze Coverage** note explaining the `/search/shows` engine (Elasticsearch fuzzy search, relevance + popularity ranking, AKA-name matching).
- Annotated each of the six **Potential Improvements** inline with whether TVMaze already handles it (punctuation, partial titles, alternate names, basic ranking = already covered; articles = mostly covered/low value; abbreviations = the real gap).
- Added a **Remaining Work (app-side)** subsection narrowing it to abbreviation aliasing and app-purpose ranking, plus a reminder to validate during beta first.

No code or other sections were touched.

What to check: open `Release Readiness.md` and confirm the Search section reads the way you want — particularly whether you agree with my "low value" call on article-stripping and the framing of "improve ranking" as app-purpose re-ordering. If you'd rather keep the original flat bullet list and just append a coverage summary, I can restructure it that way.

## User

Yes, please add coverage summary instead

## Assistant

I'll restore the original flat bullet list of potential improvements and replace my inline annotations with a separate coverage summary appended after the list.

Done. The original flat **Potential Improvements** bullet list is restored unchanged, and I replaced the inline annotations with a dedicated **TVMaze Coverage Summary** appended right after it. It groups the items into: already handled by TVMaze, mostly covered/low value (articles), and the real app-side opportunities (abbreviation aliasing + app-purpose ordering), with the beta-validation reminder.

What to check: open `Release Readiness.md` and confirm the summary placement and wording read well. Other sections are untouched.

## User

Looks good, thanks.

I have noticed a problem with our search behavior.  When I search for something like "Star Trek", not all of the expected matches are returned.  By comparing with search results from the TVMaze website I can see that we are only displaying the first page of results.  Is there a bug in our search code that is not requesting all pages? (just answer the question, don't fix yet)

## Assistant

Let me verify how TVMaze's search endpoint actually behaves (pagination/result cap) before answering. I'll check the code path and the live API.

No — it's not a pagination bug in our code, because TVMaze's `/search/shows` endpoint isn't paginated at all.

What I found:

- Our code makes a single request to `/search/shows?q=...` and maps everything it returns. There's no page loop, but there's also nothing to loop over.

```40:48:NextSeason/Services/TVMazeClient.swift
    func searchShows(matching query: String) async throws -> [Show] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(url: baseURL.appending(path: "search/shows"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        let results: [ShowSearchResultData] = try await get(components)
        return results.map { $0.show.toDomain() }
    }
```

- I queried the live API: `/search/shows?q=star trek` returns exactly **10** results, `q=girls` returns **10**, and adding `&page=1` changes nothing. The endpoint caps results (~10) and ignores a `page` parameter — there are no additional pages to fetch.

So the reason you see fewer matches than the TVMaze website is **not** that we're dropping pages. It's that the public `/search/shows` API returns a fixed, capped, relevance-ranked result set, while the TVMaze *website* uses a different/internal search that surfaces more matches. Our code is consuming the API correctly given how that endpoint works.

If you want more "Star Trek" matches, the fix isn't pagination — it'd be a different approach (e.g. a different endpoint/strategy). Happy to dig into options when you want to address it.
