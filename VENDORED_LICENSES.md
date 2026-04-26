# Vendored Licenses

This file records third-party source code that has been vendored into this
repository, along with the upstream license terms. ActiveRecall's own license
is in [LICENSE](LICENSE).

## rb-fsrs

- **Vendored at:** [`lib/active_recall/algorithms/fsrs/internal.rb`](lib/active_recall/algorithms/fsrs/internal.rb)
- **Upstream:** https://github.com/open-spaced-repetition/rb-fsrs
- **Version:** 0.9.0 (commit pulled from the published gem)
- **License:** MIT
- **Reason for vendoring:** The published `fsrs` 0.9.0 gem pins
  `activesupport ~> 7.0`, which excludes Rails 8. ActiveRecall supports
  Rails 8, so the code was vendored under `ActiveRecall::FSRS::Internal`.
  The constraint has been widened on rb-fsrs `master`; revisit the
  dependency-vs-vendoring decision once a release with the wider
  constraint ships.

### Local divergences from upstream

- `Scheduler#schedule_new_state` uses `1.minute` / `5.minutes` /
  `10.minutes` in place of upstream's bare integer arithmetic
  (`now + 60`, `now + (5 * 60)`, `now + (10 * 60)`). With `now` as a
  `DateTime`, the upstream form adds days, not seconds, scheduling new
  cards rated Again/Hard/Good 60 / 300 / 600 days out instead of
  1 / 5 / 10 minutes. Tracks upstream PR
  https://github.com/open-spaced-repetition/rb-fsrs/pull/9.

### Upstream license text

```
The MIT License (MIT)

Copyright (c) 2024 clayton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
