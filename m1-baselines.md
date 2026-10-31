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
