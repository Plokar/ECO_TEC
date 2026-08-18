# Firebase backend

Run everything here from this directory.

```bash
npm install -g firebase-tools
firebase login
firebase use <your-firebase-project-id>

firebase deploy --only firestore:rules,firestore:indexes,storage
```

Then seed the content the app needs on day one:

```bash
npm install firebase-admin
# key from: Firebase console -> Project settings -> Service accounts
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json node seed.mjs
```

`seed.mjs` is idempotent — every write is keyed by a stable document id, so
re-running updates in place instead of duplicating. It validates its own quest
data against the detector's class list first, because a typo'd class name makes a
quest quietly impossible to complete.

Also enable, in the console: **Authentication → Email/Password and Anonymous**.

## What each index is for

`firestore.indexes.json` can't carry comments, so the mapping lives here. Deploy
these — without them the leaderboard and league tabs fail at runtime with a
console link instead of data.

| Collection | Fields | Query |
|---|---|---|
| `users` | `city` ↑, `xp` ↓ | `DataService.leaderboard(Scope.city)` |
| `users` | `country` ↑, `xp` ↓ | `DataService.leaderboard(Scope.country)` |
| `users` | `school` ↑, `xp` ↓ | `DataService.leaderboard(Scope.school)` |
| `leagues` | `kind` ↑, `points` ↓ | `DataService.leagueTable()` — city vs city |
| `submissions` | `uid` ↑, `createdAt` ↓ | `DataService.recentSubmissions()` |
| `quests` | `isDaily` ↑, `__name__` ↑ | `DataService.dailyQuest()` / `bonusQuests()` |

## Data model

```
users/{uid}          displayName, displayNameLower, city, country, school,
                     xp, ecoPoints, co2SavedG, classCounts{}, streak{}, friends[]
quests/{id}          title, targetClasses[], targetCount, xpReward, pointsReward,
                     isDaily, verification, sponsorName?
submissions/{id}     uid, questId, photoUrl, detections[], itemsCounted,
                     classCounts{}, xpAwarded, lat, lng, createdAt (server)
leagues/{kind:name}  kind, name, points, items, co2SavedG
mapPins/{id}         kind, lat, lng, title, resolved, uid
rewards/{id}         title, partner, costPoints, stock, terms
redemptions/{id}     uid, rewardId, costPoints, createdAt
```

`displayNameLower` exists because Firestore range queries are case-sensitive and
there is no substring search — friend lookup does a prefix range over it.

## About the rules

The app awards XP on the device so rewards land instantly and work offline, which
makes `firestore.rules` the only thing between a patched client and an invented
leaderboard. `FieldValue.increment` is resolved *before* rules run, so the rules
bound the resulting values rather than trusting the caller: XP only moves forward
and by at most 5000 per write, EcoPoints can't go negative, history is
append-only, and reward stock can only be decremented by exactly one.

Two things it does **not** solve, both listed in the root README's gaps table:

- A faked photo still passes, because detection happens on the user's device. A
  Cloud Function re-running the model on the upload, plus App Check, is the fix.
- Any signed-in user can add to a city's league total. Same fix.

### Verify the friend rule before relying on it

The rule that lets you add only *yourself* to another player's friend list uses
set differences, and it has not been exercised against the emulator:

```bash
firebase emulators:start --only auth,firestore
```

Check that a signed-in user can add and remove themselves from someone else's
`friends` array, and cannot touch any other field or insert a third party's uid.
