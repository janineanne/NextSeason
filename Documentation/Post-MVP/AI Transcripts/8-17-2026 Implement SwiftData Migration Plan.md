# SwiftData schema versioning

## User

Please add explicit SwiftData schema versioning and migration infrastructure to NextSeason in preparation for the App Store release.

This task is not intended to change the current persisted data model. The goal is to establish the current model as the explicit V1 schema so that future releases can migrate safely from the schema that ships in 1.0.

Goals

1. Define the existing production SwiftData schema as V1 using VersionedSchema.
2. Add a SchemaMigrationPlan that establishes V1 as the current schema.
3. Update production and test ModelContainer creation to use the versioned schema and migration plan.
4. Preserve existing user watchlist data, including data created by current TestFlight builds that used the existing unversioned TrackedShowEntity.
5. Add focused tests for the new persistence setup.
6. Do not change the separate ShowIDMappingDatabase migration/replacement mechanism.

Current state

NextSeason currently has a single SwiftData persistence model, TrackedShowEntity.

Production creates its SwiftData container using the model directly, approximately:

ModelContainer(for: TrackedShowEntity.self)

There is currently no explicit VersionedSchema or SchemaMigrationPlan.

The existing persisted model represents user-owned data: the user’s watchlist plus associated refresh/notification state. Preserving this data across app upgrades is therefore important.

The ShowIDMappingDatabase is separate, reproducible application data backed by SQLite. It already has its own schema/version replacement strategy and should remain independent of SwiftData migration work.

Implementation requirements

1. Add a V1 SwiftData schema

Introduce an appropriately named VersionedSchema, such as:

enum NextSeasonSchemaV1: VersionedSchema

Use a semantic schema version corresponding to the first released schema.

The V1 schema must describe the existing TrackedShowEntity model exactly as it exists today. Do not opportunistically rename fields, change types, alter optionality, change defaults, add constraints, or otherwise modify the persistence contract as part of this task.

Choose a structure that will remain clean when we eventually need NextSeasonSchemaV2, V3, etc.

In particular, consider whether the persistence model should live within the schema namespace, e.g.:

NextSeasonSchemaV1.TrackedShowEntity

versus retaining the current top-level model type.

Choose whichever approach produces the cleanest long-term migration architecture with the least unnecessary disruption to the rest of the application. Do not perform a broad refactor merely for namespacing aesthetics.

2. Add the migration plan

Introduce something along the lines of:

enum NextSeasonMigrationPlan: SchemaMigrationPlan

For now:

* schemas should contain only V1.
* stages should be empty.

Do not invent a migration stage when there is no V1 → V2 migration yet.

The purpose of this work is to establish the baseline schema that future releases will migrate from.

3. Update ModelContainer construction

Update the production SwiftData container to use:

* the V1 schema
* NextSeasonMigrationPlan

Do the same anywhere the app creates an in-memory SwiftData container for UI tests or other runtime configurations where the production model is intended to be represented.

Avoid duplicating schema/container construction logic unnecessarily.

Keep dependency injection and the existing composition-root responsibilities intact.

4. Preserve existing TestFlight data

This is a critical requirement.

Current TestFlight builds may already have a SwiftData store created using the existing unversioned:

TrackedShowEntity

model.

The new versioned implementation must not silently make those existing stores unreadable or cause SwiftData to create an empty replacement store.

Investigate SwiftData’s behavior when moving from this existing unversioned model declaration to the explicit V1 schema.

Where practical, add an automated test that exercises this transition.

If faithfully reproducing the old unversioned store in an automated test is impractical, document that limitation clearly and make the implementation as compatible as SwiftData permits.

Do not add destructive fallback behavior such as deleting the persistent store if opening it fails.

Before we consider this work complete, an upgrade test on a device/simulator with an existing watchlist should be possible:

1. Install/run the current build and create several watchlist entries.
2. Install the new build over it without deleting the app.
3. Verify all watchlist entries and their persisted state remain intact.

5. Add persistence tests

Add focused tests appropriate to the project’s existing testing style.

At minimum, verify that:

* A ModelContainer can be created using NextSeasonSchemaV1 and NextSeasonMigrationPlan.
* A TrackedShowEntity containing representative values can be inserted, saved, fetched, and reconstructed correctly.
* All persisted fields survive the round trip, rather than testing only an ID or title.

The round-trip test should be useful as a baseline contract test for the schema that will ship as V1.

If there is a sensible way to retain a V1 store fixture for future migration tests without adding significant complexity, structure the tests so that doing so later will be straightforward. Do not build an elaborate fixture framework before we actually have V2.

6. Leave ShowIDMappingDatabase alone

Do not modify:

* its SQLite schema
* its schema-version handling
* its replacement/update logic
* its initialization architecture

It is reproducible app data and has deliberately different persistence requirements from the user’s SwiftData watchlist.

Scope discipline

Please keep this change narrowly focused.

Do not:

* redesign TrackedShowEntity
* rename persisted properties
* change business logic
* refactor unrelated repositories or services
* alter analytics/logging
* change notification behavior
* introduce V2 prematurely
* add speculative migrations
* add destructive recovery behavior
* convert the mapping database to SwiftData

Small supporting refactors are fine when they directly make the migration infrastructure clearer or remove obvious duplication.

Documentation/comments

Add concise comments where they explain a non-obvious migration constraint, especially where future developers need to understand that the V1 schema represents the persistence contract shipped to users.

Avoid comments that merely restate Swift syntax.

Final review

When finished:

1. Run the relevant unit tests.
2. Run the full test suite if practical.
3. Check for compiler warnings.
4. Review the diff for accidental unrelated changes.
5. Explain:
    * the schema/version structure you chose,
    * how existing unversioned TestFlight stores are expected to transition to V1,
    * what migration-related tests were added,
    * and any limitation that still requires the manual upgrade test described above.

Please do not make unrelated cleanup changes while implementing this task.

## Assistant

I'll start by reading the SwiftData and testing skills, then inspect how `TrackedShowEntity` and `ModelContainer` are set up today so we can add V1 versioning without changing the persisted model.

Skills used: `swiftdata-pro`, `swift-testing-pro`, `swift-concurrency-pro`. Next I’ll read the SwiftData versioning rules and locate the current model and container setup.

I'll keep `TrackedShowEntity` as the top-level model so existing TestFlight stores keep the same entity hash, and add V1 schema, a migration plan, and a shared container factory around it.

Simulator listing was blocked by the sandbox, so I’ll list devices and compile the new schema tests with full permissions.

The three new schema tests passed, including the unversioned-store transition. Next I’ll scan the build for warnings and run the full unit suite.

The isolated schema tests passed, but the in-memory round-trip failed in the full suite—likely a parallel SwiftData isolation issue. I’ll pull the failure details next.

The suite failure was a brittle raw-JSON `Data` comparison, not a lost field. I’ll compare the decoded `NextSeasonStatus` instead and isolate in-memory stores so parallel tests don’t share a container.

SwiftData now has an explicit V1 schema and migration plan, without changing the persisted `TrackedShowEntity` contract. Existing TestFlight watchlists should keep opening from the same `default.store`.

Skills used: `swiftdata-pro`, `swift-testing-pro`, `swift-concurrency-pro`.

## Schema / version structure

`TrackedShowEntity` stays a **top-level** `@Model`. I did not nest it as `NextSeasonSchemaV1.TrackedShowEntity`.

That is the safer 1.0 choice: TestFlight stores were created from this exact type, so V1 is generated from the same entity name and attribute hash. Nesting now would be namespacing only, and it would risk a hash mismatch that makes those stores unreadable.

The version ladder is ready for V2 later:

- `NextSeasonSchemaV1` — `Schema.Version(1, 0, 0)`, models: `[TrackedShowEntity.self]`
- `NextSeasonMigrationPlan` — schemas: `[V1]`, stages: `[]` (no invented V1→V2 stage)
- `NextSeasonModelContainer.make()` — shared factory used by production, UI-test in-memory setup, and tests

Production still uses SwiftData’s default Application Support `default.store`. There is no custom URL and no delete-on-failure recovery.

When a real model change ships, add `NextSeasonSchemaV2`, snapshot today’s V1 shape if needed, and add a migration stage. By then stores opened by this build will already carry version `1.0.0`.

## Unversioned TestFlight → V1

Apple’s guidance is that an unversioned store maps to V1 when the entity hash matches. Because V1 lists the same top-level `TrackedShowEntity`, SwiftData should:

1. Recognize the existing store as V1
2. Open it in place (not create an empty replacement)
3. Write version `1.0.0` into store metadata

An automated test covers the closest in-process equivalent: create a store with `ModelContainer(for: TrackedShowEntity.self)`, then reopen it with `NextSeasonModelContainer.make()`. That test passed, including every persisted field.

## Tests added

`NextSeasonSchemaTests` covers:

1. V1 is `1.0.0`, lists only `TrackedShowEntity`, and the plan has no stages
2. A versioned in-memory container inserts, saves, fetches, and reconstructs a representative row
3. An unversioned on-disk store opens through the versioned path

The round-trip uses non-default values for every stored field (`tvMazeID`, `name`, both URLs, `summaryHTML`, `statusRaw`, `nextSeasonSnapshot`, both timestamps, both signatures, `isStale`, `dateAdded`) and checks both raw attributes and `toDomain()`.

`ShowIDMappingDatabase` was not changed.

## Test results

- New schema tests: passed
- Full unit suite: **182 tests in 31 suites passed**
- No compiler warnings from these files

## Manual upgrade test still required

The automated transition test uses the **current** `TrackedShowEntity` type, not a separately compiled pre-versioning class. Please still do this on a device or simulator that already has a watchlist:

1. Install/run the current TestFlight (or `main`) build and add several shows
2. Install this build over it **without deleting the app**
3. Confirm every watchlist row and its refresh/notification state is intact

If that upgrade succeeds, V1 is a safe baseline for later migrations.

## User

Please make one focused correction to the SwiftData migration infrastructure that was just added.

The overall implementation is good. Do not redesign it or make unrelated changes.

Problem

NextSeasonSchemaV1 currently declares:

nonisolated enum NextSeasonSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [TrackedShowEntity.self]
    }
}

The problem is that TrackedShowEntity remains the same top-level model type used by the current application.

This means V1 is not truly frozen as a historical schema. If TrackedShowEntity is changed in the future for V2, NextSeasonSchemaV1.models will also begin referring to that changed model. At that point we would no longer have an immutable representation of the schema that shipped as V1.

SwiftData versioned schemas should preserve each released schema independently so that, for example, a future migration can distinguish between:

NextSeasonSchemaV1.TrackedShowEntity

and:

NextSeasonSchemaV2.TrackedShowEntity

Important compatibility constraint

There is a reason the current implementation retained the existing top-level TrackedShowEntity: current TestFlight installations may already have an on-disk SwiftData store created using that unversioned model.

The current comment notes that retaining the existing type keeps the entity name/version hash aligned with those stores.

Do not solve the historical-schema problem at the expense of compatibility with existing TestFlight stores.

Before changing the model’s structure or identity, investigate how SwiftData determines the persistent entity identity/version hash and what mechanism should be used to preserve compatibility when moving the existing model into a versioned schema.

If SwiftData provides an appropriate original-name/renaming mechanism or other supported way of retaining the existing persistent identity, use that rather than assuming that simply nesting the model is harmless.

Desired architecture

The long-term architecture should allow V1 to remain permanently unchanged after this task.

Conceptually, I expect something like:

enum NextSeasonSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [TrackedShowEntity.self]
    }
    @Model
    final class TrackedShowEntity {
        // Exact V1 persisted model
    }
}

However, do not blindly implement this exact example if nesting the type would break compatibility with stores written by the existing unversioned model.

Choose the SwiftData-supported implementation that satisfies both requirements:

1. NextSeasonSchemaV1 is a genuinely frozen representation of the V1 persistence schema.
2. Existing stores created by the current unversioned TrackedShowEntity remain readable without destructive recovery.

Application/repository code should use the model belonging to the current schema in whatever clean manner is appropriate. With V1 as the only schema today, that would normally mean the V1 model. The design should make adding a distinct NextSeasonSchemaV2.TrackedShowEntity straightforward later.

Preserve the exact V1 persistence contract

Do not change any persisted property as part of this work.

V1 must retain exactly the current:

* property names
* property types
* optionality
* defaults
* uniqueness/other attributes
* relationships, if any
* persistent entity identity required for compatibility

This is an architectural correction, not a schema change.

Tests

Update the existing persistence tests as necessary for the corrected model structure.

Keep the existing strong round-trip coverage that populates representative non-default values for all persisted fields and verifies reconstruction into the domain model.

Also retain the existing compatibility test that creates an on-disk store without the migration plan and then opens it using the V1 migration plan.

Be precise in the comments about what that automated test does and does not prove. It is acceptable—and expected—that it cannot perfectly reproduce a store generated by a previously compiled TestFlight binary.

Do not weaken or remove the requirement for the manual upgrade test:

1. Run/install the existing TestFlight-era build.
2. Create several watchlist entries.
3. Install the new build over it without deleting the app.
4. Verify that the existing watchlist and persisted state remain intact.

If the corrected architecture introduces any compatibility uncertainty that the automated test cannot resolve, call that out explicitly rather than hiding it with destructive recovery behavior.

Do not add destructive fallback

Under no circumstances should failure to open an old store result in automatically:

* deleting the store,
* recreating the store,
* clearing the watchlist,
* or otherwise discarding user data.

A migration/opening failure should remain visible as a failure rather than silently causing data loss.

Keep the rest of the implementation

Unless necessary for this correction, retain the existing:

* NextSeasonMigrationPlan
* NextSeasonModelContainer
* production container configuration
* UI-test/in-memory container configuration
* persistence test coverage
* roadmap changes

NextSeasonMigrationPlan should still contain only V1 and have no migration stages. There is still no V2 and therefore no real migration stage to define.

Do not touch ShowIDMappingDatabase or its SQLite migration/replacement strategy.

Scope discipline

Please do not:

* introduce V2
* create a speculative migration
* change business logic
* change notification behavior
* change analytics or diagnostics
* refactor unrelated repositories/services
* modify the mapping database
* make unrelated cleanup changes

Final review

When finished:

1. Run the relevant persistence tests.
2. Run the full test suite if practical.
3. Check for compiler warnings.
4. Review the diff for unrelated changes.
5. Explain specifically:
    * how V1 is now frozen independently from future schemas,
    * how the persistent identity of the old unversioned TrackedShowEntity is preserved,
    * why existing TestFlight stores are expected to remain readable,
    * what the automated compatibility test actually proves,
    * what still needs to be verified with the manual upgrade test,
    * and how a future NextSeasonSchemaV2 can now be added without mutating V1.

If investigation shows that SwiftData cannot safely satisfy both frozen historical schemas and transparent conversion of the existing unversioned TestFlight store using the approach we expect, stop and explain the conflict rather than choosing a potentially data-losing workaround.

## Assistant

I'll investigate how SwiftData identifies persisted entities and version hashes before moving `TrackedShowEntity` into a frozen V1 schema, so we don't break existing TestFlight stores.

I'll inspect SwiftData's entity-naming and version-hash APIs next, then check every `TrackedShowEntity` call site so a frozen V1 type doesn't break the rest of the app.

`@Attribute(originalName:)` only covers property renames. Next I’ll inspect SwiftData’s `Schema.Entity` APIs and compare entity names for a top-level model versus a nested one.

Investigation result: SwiftData keys entity identity by `Schema.Entity.name` (`Schema.entityName(for:)`). There is no entity-level `originalName`—only attributes have that. Apple’s samples keep the class name `TrackedShowEntity` when nesting, which is what preserves the store identity. I’ll nest the model that way, add a current-schema typealias, and assert the entity name stays `TrackedShowEntity`.

All four schema tests passed, including the entity-name assertion. Next I’ll run the full unit suite and review the diff.

V1 is now a frozen nested schema. The persisted contract is unchanged, and the entity name that TestFlight stores already use is still `TrackedShowEntity`.

Skills used: `swiftdata-pro`, `swift-testing-pro`, `swift-concurrency-pro`.

## How V1 is frozen

`TrackedShowEntity` is now `NextSeasonSchemaV1.TrackedShowEntity`. App and repository code still use `TrackedShowEntity` via:

```swift
typealias TrackedShowEntity = NextSeasonSchemaV1.TrackedShowEntity
```

A future V2 adds `NextSeasonSchemaV2.TrackedShowEntity` and retargets that alias. The V1 nested type is left alone, so `NextSeasonSchemaV1.models` cannot accidentally pick up V2’s shape.

No persisted property, type, optionality, default, or `@Attribute(.unique)` changed.

## How the old persistent identity is preserved

SwiftData identifies an entity by `Schema.Entity.name` (`Schema.entityName(for:)`). There is **no entity-level `originalName`**. `@Attribute(originalName:)` only maps renamed properties.

So the nested class keeps the name `TrackedShowEntity`. That is the supported way to keep the same persistent identity; renaming the class would be a new entity, and SwiftData cannot remap that.

A test now asserts:

- `Schema.entityName(for: NextSeasonSchemaV1.TrackedShowEntity.self) == "TrackedShowEntity"`
- V1’s `entitiesByName` key is `"TrackedShowEntity"`
- The 13 stored attribute names match the current contract

## Why TestFlight stores should still open

Apple’s guidance is that an unversioned store maps to a nested V1 model when the version hash matches. That hash is entity name + attributes. Both are unchanged, the default `default.store` URL is unchanged, and there is still no delete-on-failure path.

`NextSeasonMigrationPlan` still has only V1 and no stages.

## What the automated compatibility test proves

It still writes with `ModelContainer(for: TrackedShowEntity.self)` (no plan), then reopens with the V1 plan, and checks every field.

That proves: a store written without versioning, whose entity name and attributes match V1, can be opened by the production path.

It does **not** prove a store written by a previously compiled TestFlight binary whose `TrackedShowEntity` was a top-level `@Model`. After this change, `TrackedShowEntity` is a typealias to the nested V1 type, so the test cannot reproduce that older binary.

## Manual upgrade test still required

1. Install/run the existing TestFlight-era build.
2. Create several watchlist entries.
3. Install this build over it without deleting the app.
4. Confirm every row and its refresh/notification state is intact.

If opening fails, the app still logs and `fatalError`s. It does not delete or recreate the store.

## Adding V2 later

1. Leave `NextSeasonSchemaV1.TrackedShowEntity` unchanged.
2. Add `NextSeasonSchemaV2` with its own nested model.
3. Add a real migration stage (lightweight or custom).
4. Point the typealias at V2.
5. Keep `NextSeasonModelContainer` opening the current schema + plan.

## Tests

- Schema tests: 4 passed (ladder, entity name/attributes, round-trip, unversioned reopen)
- Full unit suite: **183 tests in 31 suites passed**
- No compiler warnings from these files
- Diff is limited to the schema types, the nested model + typealias, plan comment, and persistence tests

