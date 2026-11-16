# StartupSequence

`StartupSequence<T>` presents consumer-owned full-page scenes in order. Each
scene stays visible for its minimum duration. After the scenes, the loading
screen shows observable job progress while `load` and the job queue run. The
result opens the app only after initialization and the minimum loading duration
complete. A failed load or job opens the consumer's retry screen. Retry runs the
initialization again without replaying introductory scenes.

Adjacent asynchronous jobs start together; a synchronous job waits for earlier
ones and completes before later jobs begin. Jobs report a fraction from zero to
one through `StartupProgress.report`. The consumer owns the content, labels,
tasks, authorization, and app destination. Gicho owns ordering, barriers,
timers, transition, retry, and disposal-safe completion.

`transition` chooses `fade`, `slide`, `scale`, or `none`, and
`transitionDuration` sets its speed. Consumers can put these values in their
schema-validated application configuration. `loadLabel` names the primary
typed loader in the same progress list as optional jobs.
