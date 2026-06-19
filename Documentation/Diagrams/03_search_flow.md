# Show Search Flow

```mermaid
sequenceDiagram
    actor User
    participant SearchView
    participant SearchViewModel
    participant TVMazeClient
    participant TVMazeAPI as TVMaze API

    User->>SearchView: Enters show search text
    SearchView->>SearchViewModel: Submit search query
    SearchViewModel->>TVMazeClient: searchShows(query)
    TVMazeClient->>TVMazeAPI: GET show search endpoint
    TVMazeAPI-->>TVMazeClient: JSON search results
    TVMazeClient-->>SearchViewModel: Decoded show models
    SearchViewModel-->>SearchView: Search results state
    SearchView-->>User: Display matching shows
```

## Purpose

This diagram shows the search path from user input to decoded TVMaze results.

The important boundary is `TVMazeClient`: the rest of the app should not need to know the details of URL construction, query items, HTTP requests, or JSON decoding.
