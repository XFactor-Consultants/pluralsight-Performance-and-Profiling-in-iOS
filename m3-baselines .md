# TaskFlow baselines

- Build: Release, using Product > Profile (Command-I)
- Simulator: iPhone 17 Pro, iOS 26.5 (Xcode 26.6)
- Mac: plugged in, other apps closed (record model here)
- App state: fresh install, archive filled, then relaunched (branch module-1)

## Symptoms and goals

- Launch: from tap to first frame of the task list (goal: at least 15 % faster than the baseline median, and beyond its range)
- Idle CPU: Tasks screen untouched for 10 seconds (goal near 0 %)
- Memory: after opening and closing 10 tasks (goal back within 5 MB of launch)
- Activity: loads per visit (goal exactly 1)
- Rendering: time spent counting open tasks during a scroll of the task list (goal: no longer a visible share of main-thread time)

## Baselines

- Launch to first frame: 8.75 s, median of 5 (range 8.38 to 11.34 s)
- Build Search Index interval: 337 ms per build, median of 5 (range 329 to 340 ms), runs twice per launch
- Memory after launch: 198 MB (Xcode gauge, Debug build)
- Memory after 10 tasks: 233 MB (Xcode gauge, Debug build)
- Idle CPU on Tasks: 13 to 25 % (Xcode gauge, Debug build)
- Activity loads on first visit: 2 (Loads counter)

## Launch procedure

Force-quit, wait 10 seconds, Profile in Release, record until the task list appears, five runs.

Stop the moment the task list appears. Reaction time is part of the number, so use the same method every time.

Mac plugged in, other apps closed.

## Test 10/31/26: After launch and responsiveness fixes (Simulator)

- Launch to first frame: 9.41 s, median of 3 (range 8.81 to 9.97 s); baseline: 8.75 s, range 8.38 to 11.34 s. Goal not met.
- Build Search Index at launch: once, in the background (was twice, on the main thread before the first frame)
- Index rebuild on return to the foreground: no (was yes)
- Idle CPU on Tasks: 3 to 5 % (Xcode gauge, Debug build; was 13 to 25 %)

## Test 11/02/26: Memory before the fix (re-measured after the launch fixes)

- Memory after launch: 198 MB (Xcode gauge, Debug build)
- Memory after 10 tasks: 239 MB (Xcode gauge, Debug build), a difference of 41 MB
- Allocations: 10 TaskDetailModel objects still alive after opening and closing 10 tasks, none freed

## Test 11/03/26: After the retain cycle fix (Simulator)

- Memory after launch: [ ] MB (Xcode gauge, Debug build)
- Memory after 10 tasks: 210 MB (Xcode gauge, Debug build)
- Difference: about [ ] MB, down from 41 MB. Goal (within 5 MB of launch) not met.

## Test 11/03/26: After image and memory-pressure fixes (Simulator)

- Avatar sizes: 3000 x 3297, 3000 x 3394, 3000 x 3734 pixels (about 125 MB decoded for the three; files total about 1.4 MB on disk)
- Memory after launch: 77.5 MB (Xcode gauge, Debug build; before the change: 198 MB, a drop of about 120 MB)
- Simulated memory warning: no meaningful change in the gauge (the cache now holds three small images)

## Test 11/03/26: Rendering baseline (Simulator)

Scroll the task list down and back for 10 seconds each way.

Release build, Time Profiler, Mac plugged in, other apps closed, median of 3 runs.

- Main-thread time in openTaskCount during the scroll: 223 ms, 83.5 % of main-thread work (267 ms total)

## Test 11/03/26: After rendering fixes (Simulator)

Same procedure as the rendering baseline: scroll the task list down and back for 10 seconds each way, Release build, Time Profiler, Mac plugged in, other apps closed.

- Time in the row's list closure (TaskListView.body): about 1 ms (before: 223 ms in openTaskCount, 83.5 % of main-thread work)
- openCountsByAssignee: not listed as a separate call in the call tree
- Main-thread work for the scroll: 190 ms (before: 267 ms)
- Goal (counting no longer a visible share of main-thread time): met

Changes made: added openCountsByAssignee to TasksStore, removed openTaskCount(for:), passed openCount into TaskRowView from TaskListView.

## Test 11/04/26: Async baseline (Simulator)

One run, Release build, Swift Concurrency template, Mac plugged in, other apps closed. Order: first load of Activity, switch away and back (revisit), then open Activity and leave within a second. Times are for the view's own task (View.task in ActivityView.swift), from its creation to its last Running.

- Activity loads on first visit: 2 (Loads counter; goal exactly 1)
- Tasks started per Activity visit: 2, one from the view's task and one from an appearance callback (trace)
- Activity first load: 1.21 s (0.08 s running, 0.85 s waiting)
- Activity revisit: 0.98 s, full load repeated
- Work continuing after leaving the tab: yes (both loads ran all three requests to the end)

## Test 11/04/26: After async fixes (Simulator)

Same procedure as the async baseline: Release build, Swift Concurrency template, Mac plugged in, other apps closed, one run. Times are for the view's own task (View.task in ActivityView.swift), from its creation to its last Running.

- Activity loads per visit: 1 (was 2; goal exactly 1). The trace shows one load task and three request tasks started together.
- Activity first load: 0.81 s, 0.35 s waiting (was 1.21 s, 0.85 s). The three requests wait side by side, so the wait is the longest one (354.60 ms).
- Activity revisit: about 2 ms (was 0.98 s), served from the cache with no load task.
- Work continuing after leaving the tab: none. The data was already cached, so a cold-start early leave was not re-tested.

Changes made: independent requests started together with async let, a second request waits for the load already running, decoded result cached in ActivityStore.

## Test 11/05/26: Persistence and background baseline (Simulator)

One run, Release build, Time Profiler, Mac plugged in, other apps closed. Archive of 20,000 records (about 6,700 per teammate). The sync is simulated: SyncEngine sorts a list of 1.5 million numbers every 10 seconds, on the main actor. Trace recorded separately from the screen capture.

Procedure: wait for the task list, then 5 seconds. Open History and switch teammates three times, pausing a second between each. Go to the Tasks tab and scroll up and down for about 25 seconds, so a sync fires. Stop.

- History fetch (loadRows) for one switch: 1.31 s on the main thread, one run. Of that, 790 ms in loadRows itself (includes the fetch), 444 ms sorting and 42 ms filtering in memory.
- Main-thread time in performSync for one sync: 389 ms, one run. Of that, 362 ms sorting and 25 ms building the list.
- performSync thread: Main Thread

Goals: History fetch much smaller and no longer growing with the archive; performSync no longer on the main thread during a scroll.

