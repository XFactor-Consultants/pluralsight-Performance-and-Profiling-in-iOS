# TaskFlow: Performance and Profiling in iOS

A practical guide to measuring, diagnosing, fixing and proving performance changes in an iOS app, using the seeded **TaskFlow** project from the Pluralsight course *Performance and Profiling in iOS*.

Source: https://github.com/XFactor-Consultants/pluralsight-Performance-and-Profiling-in-iOS

> All numbers here are the course author's, measured in the **iOS Simulator** on one Mac and recorded in `baselines.md`. Yours will differ. The method is what transfers. Items marked **[CONFIRM]** couldn't be verified for every Xcode version, so check them on your own. If this README and `baselines.md` disagree, `baselines.md` wins.

## Contents

1. [Course overview](#1-course-overview)
2. [Prerequisites and project notes](#2-prerequisites-and-project-notes)
3. [The core loop](#3-the-core-loop)
4. [Simulator limits](#4-simulator-limits)
5. [Which tool for which symptom](#5-which-tool-for-which-symptom)
6. [Using the tools](#6-using-the-tools)
7. [Writing baselines.md](#7-writing-baselinesmd)
8. [Fair comparisons and common traps](#8-fair-comparisons-and-common-traps)
9. [Results at a glance](#9-results-at-a-glance)
10. [Reporting findings](#10-reporting-findings)
11. [Troubleshooting](#11-troubleshooting)
12. [Checklist](#12-checklist)
13. [Open items to confirm](#13-open-items-to-confirm)

---

## 1. Course overview

TaskFlow is a task-management app with thousands of tasks, an Activity feed and a 20,000-record History archive. It ships with performance problems on purpose. Across four modules you turn vague complaints into numbers, find the causes with traces, fix them one at a time, and prove each fix.

### Module 1: Establishing a performance measurement workflow

Complaints ("it feels slow") become reproducible symptoms with goals. You create `baselines.md`, capture first numbers from Xcode's gauges, then record launch and idle traces in Time Profiler to fill in the rest. You learn where the Simulator misleads and why plausible-sounding optimizations often target the wrong cost. **No code changes.**

### Module 2: Analyzing launch time, responsiveness and memory

You fix what Module 1 found: launch work deferred until after the first frame, the search index built once in the background, and the per-second timer moved into its own small view. You then use Allocations with reference counting to find a retain cycle (a strong `self` in a stored closure), fix it, and cut launch memory by downsampling oversized avatar images and handling memory warnings.

### Module 3: Optimizing SwiftUI rendering and data-layer hotspots

Three more investigations: a scroll stall caused by counting open tasks once per row, an Activity screen with duplicate loads and serial waits (fixed with coalescing, concurrent requests and a cache), and a slow History fetch plus a simulated sync running on the main thread (fixed with a filtered, limited query and a detached background task).

### Module 4: Improving efficiency and validating improvements

Energy concepts (wakeups, writes, network) with one code change to the sync banner, then the heart of the module: confirming fixes with comparable traces, naming the traps, and writing a verdict for every fix. You finish by documenting findings, drafting a report with an AI assistant, checking every number yourself, and committing the result.

## 2. Prerequisites and project notes

- Experience with SwiftUI, Observation, remote data, local persistence (SwiftData), basic Swift Concurrency, and debugging in Xcode.
- Xcode 26.x. The course used Xcode 26.6, iPhone 17 Pro Simulator, iOS 26.5.
- A Mac you can keep plugged in with other apps closed while measuring.
- The project uses **Default Actor Isolation = MainActor** (Build Settings), so code runs on the main thread unless you opt out. This is why background work needs `nonisolated` / `Task.detached`.
- `baselines.md` lives in the repo root next to this README, so it shows up in every diff.
- `SyncEngine` is test scaffolding that simulates a sync. Remove it before real use.

## 3. The core loop

```
symptom -> baseline -> trace -> ONE change -> measure again -> keep or revert -> record
```

- Fixing starts only after the symptom can be repeated on demand.
- A number without its conditions can't be compared with anything.
- Change one thing at a time.
- Judge against the baseline's **range**, not a single number. Differences inside the range are noise.
- If the number doesn't move, say so and take the change out.
- A goal you missed gets written down as missed.

## 4. Simulator limits

- It runs on your Mac's CPU, GPU and memory, so absolute numbers come out optimistic.
- It doesn't enforce device memory limits or thermal throttling. **Simulate Memory Warning** sends the notification but won't terminate the app, so verify the app's *response*.
- It can't report **energy**, and the SwiftUI instrument's **Hitches** lane isn't available in it.
- Compare Simulator numbers only with other Simulator numbers, same Mac.
- When an absolute number matters, confirm on a real device: one your users actually own (ideally older or mid-range), cool and idle, on the same OS build, with realistic data and network conditions.

## 5. Which tool for which symptom

| Symptom | Notice it with | Explain it with |
|---|---|---|
| Slow launch | Stopwatch / signposts | Time Profiler on a Release launch |
| CPU busy when idle | Xcode CPU gauge | Time Profiler on the idle stretch |
| Scroll stutters | Feel / gauge | Time Profiler on the scroll (Hitches lane on a device) |
| Memory keeps growing | Xcode Memory gauge | Allocations with generations, then reference counts |
| Abandoned memory | Memory gauge | Leaks, plus Allocations reference history |
| Screen loads slowly or twice | On-screen counter | Swift Concurrency template |
| Slow fetch | Feel | Time Profiler on the interaction |
| Background work hurts scrolling | Feel | Time Profiler across a scroll, check the thread |
| Battery drain | Device only | Instruments energy tools, Xcode energy gauge **[CONFIRM names]** |

**Gauges tell you something is wrong. Traces tell you where and why.** If the gauges look healthy, you usually don't need a trace.

## 6. Using the tools

### Xcode gauges

Run with **Command-R**, open the Debug navigator with **Command-7**, and click CPU or Memory. Gauges come from a **Debug** build, so use them to *notice* problems and write rough numbers, labeled "Xcode gauge, Debug build." Never compare a Debug gauge to a Release trace.

- **Idle CPU:** touch nothing on the Tasks screen for 10 seconds. A healthy app settles near 0 %.
- **Memory staircase:** let memory settle after launch, open and close ten different tasks, wait 5 seconds, read again. Steps up that never come back down mean something holds the closed screens.
- **On-screen counters** (like the Activity Loads counter) are the cheapest measurement there is.

### Instruments basics

1. **Product > Profile (Command-I).** Xcode builds **Release**, which is what users run (Debug skips optimizations and gives the wrong timings), then opens Instruments with the target selected.
2. Pick a template, press **Record**. Instruments launches the app fresh.
3. Check the toolbar target. Templates needing hardware the Simulator lacks are shown as unsupported.
4. **Read method:** the timeline shows *when*, the detail pane shows *what*. Always **select a time range first** (the launch, one scroll, one teammate switch), then read the detail pane for that range only. Use the same selection method every time.
5. Check the **Thermal State** row reads Nominal. A hot Mac gives different numbers.
6. Save traces you'll want later.

### Time Profiler

It samples about once a millisecond, recording the call stack of each running thread. A function in many samples ran for a long time.

- **Launch:** quit the app, wait 10 seconds, record, and stop the moment the task list appears. Your reaction time is in the number, so use the same method every run. Take five runs and report the **median and range**, keeping slow cold-start runs in.
- **Read a launch** by dragging across the main thread from trace start to first usable frame. The duration is your launch number.
- **Call tree options:**
  - *Invert Call Tree* lists where CPU was actually spent first.
  - *Hide System Libraries* collapses frames you can't change, so your code rises to the top.
  - *Separate by Thread* shows which thread work lands on **[CONFIRM label]**.
  - The search field finds a function or type by name. Option-click expands a subtree and Focus on Subtree narrows to one call **[CONFIRM]**.
- **Weight** is time including callees; **Self Weight** is the row alone. Read top-down to follow the heaviest child to the cause.
- Click a row to see its heaviest stack. If it leads back to `main`, it runs at startup.
- The top row (`TaskFlowApp.$main()`) is mostly the system and app setting themselves up in a Release build. Set it aside.
- **Idle trace:** launch, touch nothing for about ten seconds, select a stretch after launch work finishes. A quiet app shows almost nothing there.

### Points of Interest (signposts)

`PerfSignposts` marks named intervals (Build Search Index, Decode Cached Feed, Warm Avatar Cache) so Instruments draws them as bars with exact durations. Add up your named intervals and compare them with the launch time: that sum is the part you can change. Adding your own intervals uses the signpost API **[CONFIRM API and category]**.

### Allocations and Leaks

Use Allocations when memory grows. It records every object and whether it's still alive.

1. Profile, double-click **Allocations**. For retain-cycle work, enable **Record Reference Counts** before recording (File > Recording Options **[CONFIRM menu name]**).
2. Wait for the list plus 10 seconds, open and close ten different tasks (about a second each), wait 5 seconds, stop. This is slow: expect to wait.
3. **Generations:** mark one after the app settles, do a small batch of the same action, mark again. Each generation lists only what was allocated since the last mark and is still alive. The same type growing by the batch size every time is your culprit.
4. In the Statistics table, search the class name, read **# Persistent / # Transient**, list the objects, and open one's **reference history** **[CONFIRM labels]**. The retain with no matching release, and its stack, shows who took the reference and never gave it back.

Two kinds of growth: memory **still referenced** (a cache that only grows; Leaks won't flag it) and memory **abandoned** (a retain cycle; Leaks finds it). Closures that capture `self` strongly and are stored on that same object are a classic cause. Fix with `[weak self]`, not `unowned` (which crashes if the closure runs after the object is freed). Then repeat the same ten visits to prove it.

### Swift Concurrency template

It shows your async tasks, not CPU: states **Creating, Running, Suspended, Continuation, Waiting, Ending** **[CONFIRM naming]**. Running time is *computing*; time on an `await` is *waiting*, and long waits appear as Continuation rows. Waiting can be overlapped; computing can be moved or shrunk.

Record: wait for the list, open the Activity tab, switch away and back, then open it and leave immediately. Filter to the screen and look for:

- **Two tasks for one visit:** two triggers started the same load.
- **Serial Continuation rows:** independent requests awaited one after another, so waits add up.
- **A repeat on revisit:** nothing was kept.
- **Tasks still running after leaving:** work that isn't cancelled.

Fixes: coalesce duplicate loads, start independent calls together so the wait is the longest rather than the sum, and cache the result. A cache costs memory and can go stale, so measure the cost of one repeat times how often users really repeat it.

### SwiftUI rendering

A hitch is a frame that missed its deadline. Re-evaluating a body is cheap. The trouble is heavy work inside a body, or far more views re-evaluating than the change needed. On a device, the SwiftUI template counts body evaluations and its Hitches lane marks missed frames. In the Simulator, record the scroll in Time Profiler (wait for the list plus 5 seconds, then scroll steadily down about 10 seconds and back about 10) and read which view's work is heavy.

Remedies: **narrow** what each view reads (hand a row the value it needs instead of letting it reach into the store), **move** expensive work out of rows (compute once where data changes), and **eliminate** per-frame costs that grow with list size. A state change in the same view as a big list (like a per-second timer) re-runs everything beneath it, so give that state a small view of its own.

### Persistence and background work

- Test at realistic scale: a query that feels instant on twenty rows can crawl on twenty thousand.
- Fetch only what the screen needs: put the **filter** in the query, **limit** the count, and request only the **properties** displayed.
- Background work still uses the CPU the interface needs. With a MainActor default, it lands on the main thread during a scroll. Lower the priority and keep it cancellable, and use a **detached** task with `nonisolated` work, since a plain task inherits the main actor.
- Moving work off the main thread isn't a speedup. The work is the same; what changed is where it runs. Report it that way.
- Verify the screen still shows the right data after the change.

### Images and memory pressure

File size isn't memory size. Decoded size is about width x height x 4 bytes, so a few small files can cost over a hundred MB. Downsample at decode time to the displayed size (points x screen scale) with ImageIO so the full-size pixels are never held. Caches you write yourself must listen for the memory warning and release what they can rebuild, then verify the app keeps working.

### Energy, wakeups and I/O (device only)

Energy follows CPU time, radios and disk. Every wakeup and request has a fixed cost, and the cheapest work is the work you skip. Three habits to hunt: **timers and polling** (run only while visible, less often, or not on a timer at all), **redundant disk writes** (check before you write, save once per batch), and **refetching data you already have** (cache, ask only for what changed).

To measure on a device, use Instruments' energy tools and Xcode's energy gauge **[CONFIRM names]**, with the same device and settings each time: idle on the Tasks screen 60 seconds, scroll 20 seconds, background 5 minutes. Read how often the app wakes, how many requests it makes, and how much it writes. Repeat after each fix and re-run launch and scroll checks, because an energy fix that slows the app hasn't helped anyone.

## 7. Writing baselines.md

It's plain text, in the repo root, and the most important artifact in the investigation.

- **Header (conditions):** build (Release via Profile), Simulator and runtime, the Mac (plugged in, other apps closed), and app state (fresh install, archive filled, then relaunched). Each line has a reason: if one changes, comparisons are off.
- **Symptoms and goals:** each complaint becomes a symptom with a checkable goal. Goals for timings are *relative* to your own baseline median and beyond its range, not absolute numbers pulled from the air.
- **Baseline lines:** blank until you measure, each saying where its number came from and how many runs. Fill them from tools, not from how the app feels.
- **A written procedure** for each test, before you run it, so anyone can repeat it.
- **One dated section per test**, same shape, with "before" next to "after."

Habits: label every number (**one run or median**, **Debug gauge or Release trace**), note **cold start or warm cache**, state plainly what you chose not to compare, and never write a number you didn't measure.

## 8. Fair comparisons and common traps

A comparison is fair only if one thing changed:

1. Same build, same device or Simulator, same data.
2. Same steps at the same pace.
3. Same selection, with the same measure read from the same place (same stretch, row and view).

Take the same number of runs as the baseline where you can, and compare medians against the range.

| Trap | Defense |
|---|---|
| A longer selection makes a total look bigger | Select exactly the same stretch |
| A warm cache makes a second run look like a fix | Note cold or warm; record both the same way |
| One run called a median | Say "one run", or take more |
| Debug gauge vs Release trace | Compare like with like; label the build |
| Changing what you read changes the question | Same row, same view, same stretch |
| Reaction time inside every launch number | Same method each run; keep it in the range |
| Fixing the plausible instead of the heavy | Size the work first |

**Size the work before you change it.** An optimization can only save time in code it touches. Count what that code does (how many items, how many times) and compare it with the cost your traces already showed. A guess that misses the trace is a wasted change.

**Check the neighbors.** After every fix, look at launch, memory and behavior. A fix that helps one number and hurts another is a tradeoff and belongs in the report.

## 9. Results at a glance

Course author's numbers, Simulator. Where the original says "one run", it is one run.

| Fix | Baseline | After | Verdict |
|---|---|---|---|
| Launch | 8.75 s, median of 5 (range 8.38 to 11.34 s) | 9.41 s, median of 3 (range 8.81 to 9.97 s) | Goal not met (inside baseline range) |
| Idle CPU (Debug gauge) | 13 to 25 % | 3 to 5 % | Improved |
| Memory after launch (Debug gauge) | 198 MB | 77.5 MB | Improved |
| Memory after 10 tasks (Debug gauge) | 239 MB | 210 MB | Goal not met (within 5 MB of launch) |
| Rendering (main-thread work during scroll) | 267 ms | 190 ms | Improved |
| Async first load | 1.21 s | 0.81 s | Improved |
| Async revisit | 0.98 s | about 2 ms (cache warm by design) | Improved |
| History fetch, one switch | 1.31 s | 50 ms (shows 50 rows) | Improved |
| Simulated sync, one sync | 389 ms on main thread | none on main; 225 ms on a worker | Moved off main thread |

Other course figures: Build Search Index 337 ms per build (range 329 to 340 ms), twice per launch; scroll baseline 223 ms of 267 ms (83.5 %) in `openTaskCount`; Activity loads per visit 2 down to 1.

> The after-10-tasks baseline appears as 233 MB in Module 1, about 240 MB in Module 2, and 239 MB in the verdict table. Keep your own `baselines.md` consistent.

Neighbor checks written down: History shows only the newest fifty records; the Activity cache adds memory that wasn't measured and its data can go stale; background priority could delay a sync; the launch and ten-task memory goals were not met.

## 10. Reporting findings

A finding has four parts, and one missing means it isn't finished:

1. **Symptom:** what the user noticed.
2. **Evidence:** what the trace showed.
3. **Change:** what you did.
4. **Measured result:** what the same measurement showed afterward.

Always include the **tradeoff** (a behavior change, extra memory, or a missed goal). A report with no costs makes a reader suspicious. One page is enough. Keep the number in a file in the repo, keep or revert the change, and commit the result.

### Drafting with an AI assistant

An assistant prefers a complete-looking page over an honest one, so constrain it.

1. **Draft:** attach `baselines.md` and ask for a one-page report using only the numbers in the file, with symptom, evidence, change, measured result and tradeoff for each finding, plus a table and a bar chart of each result as a percentage of its baseline (lower is better). Tell it to say plainly when a goal wasn't met, write "not measured" for any missing number, and add nothing that isn't in the file.
2. **Preliminary check:** ask it to quote the line in `baselines.md` behind every number and list any it can't find.
3. **The check that counts is yours.** Compare each figure against the file one at a time, cut any number that isn't there, and add what the file can't know. The assistant's check of its own work isn't the check.

Save the report next to `baselines.md` and commit them together.

### Beyond local profiling

Local profiling finds the cause; production tells you it's happening for real users. **Xcode's Organizer** reports launch, hangs, memory, disk writes and battery in the field **[CONFIRM metric names]**, and **MetricKit** lets your app collect these itself **[CONFIRM API]**. They tell you where to look; local profiling confirms the fix.

## 11. Troubleshooting

- **Instruments shows red "supported recording modes are deferred, immediate, windowed" errors:** quit Instruments fully and relaunch it. If it persists **[CONFIRM]**: open a new trace document, enable **Always use deferred mode**, stop stale `xctrace` / `DTServiceHub` processes, or reboot.
- **A template is greyed out:** it needs hardware the Simulator lacks. Use a device or fall back to Time Profiler.
- **Allocations with reference counts is very slow:** keep the session short; ten visits is enough.
- **Noisy numbers:** plug in, close other apps, check Thermal State, take more runs, keep your Stop timing consistent, compare against the range.
- **Debug gauge doesn't match Release trace:** expected. Different builds.
- **Launch didn't improve after deferring work:** that can be correct. Report it as not met.
- **Sync still on the main thread:** a plain `Task` inherits the main actor. Use `Task.detached`, mark the work `nonisolated`, and check Default Actor Isolation.
- **Pasted code won't compile:** pasting can strip backslashes or turn quotes curly. Retype key paths and string interpolations by hand with straight quotes.

## 12. Checklist

**Before recording:** Mac plugged in, other apps closed, Thermal State Nominal; Release via Profile; same Simulator, data and app state as the baseline; procedure written in `baselines.md`.

**While recording:** same steps, pace and stopping point; wait for the list plus 5 seconds; hands off during an idle test.

**Reading:** select the range first; hide system libraries; read the same row, view and stretch; record medians, ranges and run counts.

**After a change:** one change only; re-run under the same conditions; keep it only if the number moves beyond the range; check launch, memory and behavior; add a dated section and commit.

**Before trusting a report:** every number is in `baselines.md`; missed goals are stated as missed; tradeoffs are listed; you checked it yourself.

## 13. Open items to confirm

- Allocations: the Record Reference Counts menu location, class name `TaskDetailModel`, and the reference-history label.
- Call Tree option names (Separate by Thread), Option-click expansion, Focus on Subtree.
- Swift Concurrency task-state names in your Instruments version.
- Signpost API and category for your own app.
- Device-only energy tool names in Instruments and Xcode.
- Organizer metric names and the current MetricKit API.
- Instruments recording-mode fallback steps beyond quit-and-relaunch.
- The after-10-tasks memory figure (233 vs about 240 vs 239 MB) across course materials.
