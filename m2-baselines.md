# TaskFlow baselines

Build: Release, using Product > Profile (Command-I)

Simulator: iPhone 17 Pro, iOS 26.5 (Xcode 26.6)

Mac: plugged in, other apps closed (record model here)

App state: fresh install, archive filled, then relaunched (branch module-1)

## Symptoms and goals

- Launch: from tap to first frame of the task list (goal: at least 15 % faster than the baseline median, and beyond its range)

- Idle CPU: Tasks screen untouched for 10 seconds (goal near 0 %)

- Memory: after opening and closing 10 tasks (goal back within 5 MB of launch)

- Activity: loads per visit (goal exactly 1)

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

- Memory after a simulated warning: [ ] MB (was [ ] MB just before the warning)

- List after the warning: avatars reload on scroll, no blank rows
