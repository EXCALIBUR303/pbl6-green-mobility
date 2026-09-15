# Campus Green Mobility Booking & Carbon-Savings Tracker (PBL 6)

JSP + Session + JDBC app: browse live EV-shuttle/bike-slot availability, book a
seat with server-side capacity enforcement, and track estimated CO2 savings
per student.

## Stack

- **JSP** (Jakarta EE 10 / Tomcat 11) — `src/main/webapp/*.jsp`
- **Bootstrap 5.3 + Bootstrap Icons + Plus Jakarta Sans** via CDN, with a
  design-system layer in `css/style.css` (tokens, slot cards, journey motif,
  progress ring, podium, toasts) and `js/app.js` for the interactive layer
- **`js/app.js`** — dependency-free and progressive: animated counters, live
  departure countdowns, instant client-side filter/search, toast notifications,
  booking confetti, and staggered entrance reveals. Every feature enhances
  server-rendered markup, so the pages still work if the script fails to load.
- **JSTL** for presentation (`c:forEach`, `c:if`, `c:choose`, `fmt:formatDate`) — scriptlets are
  kept only for data-fetch/session logic at the top of each page
- **JavaBeans**: `Student`, `VehicleSlot`, `Booking` (`src/main/java/.../model`)
- **DAO layer** wrapping JDBC: `StudentDAO`, `SlotDAO`, `BookingDAO` (`src/main/java/.../dao`)
- **MySQL** (`db/schema.sql`) — 3 tables: `students`, `vehicle_slots`, `bookings`
- **Maven** builds the WAR; deployed to a local Tomcat

## How the syllabus objectives map to the code

| Objective | Where |
|---|---|
| JSP directives (`page`, `include`), expressions | every `.jsp`, `WEB-INF/jspf/*.jspf` includes |
| Implicit objects: `session`, `request`, `response`, `out` (via EL) | `authGuard.jspf` (session), `login.jsp` (request/response), all pages (session nav) |
| Session tracking across a multi-page flow | login sets `session.setAttribute("student", ...)`; `authGuard.jspf` checks it on every protected page |
| **Cookies** (vs sessions) | `util/CookieUtil.java`. Two cookies, both chosen because they must OUTLIVE the session: **remembered email** (`login.jsp`, 30 days, opt-in checkbox) and **recently viewed slots** (written in `confirmBooking.jsp`, read in `availability.jsp`, 7 days). Demo: log in with "remember my email" ticked, log out — `session.invalidate()` destroys the session but the email is still pre-filled, which is the whole session-vs-cookie distinction in one screenshot. No password or token is ever put in a cookie; both are `HttpOnly`. |
| DB-backed live availability | `availability.jsp` + `SlotDAO.getUpcomingSlots()` |
| Slot-capacity conflict handling (no overbooking) | `SlotDAO.tryReserveSeat()` — a single atomic `UPDATE ... WHERE booked_count < capacity`, so two simultaneous bookings can't both grab the last seat |
| Carbon-savings formula (distance x emission-factor difference) | `util/CarbonCalculator.java` |
| Minimise scriptlets, prefer JSTL/EL | all rendering in `availability.jsp`, `history.jsp`, `leaderboard.jsp` uses `<c:forEach>`/EL; scriptlets only fetch data and never appear in markup loops |

**Flow:** `login.jsp` → `availability.jsp` (browse) → `confirmBooking.jsp?slotId=`
(choose + preview savings) → `processBooking.jsp` (POST, atomic booking) →
`history.jsp` ("My Bookings & Impact").

**Stretch goals** (both done): `leaderboard.jsp` ranks students by total CO2
saved; the **monthly summary + close-out** lives on `history.jsp`, backed by
`dao/ArchiveDAO.java` and the `monthly_archives` table.

### How the monthly reset works

Three-way split so a "reset" never destroys data:

| Where | Meaning |
|---|---|
| `bookings` | permanent record — never touched by a reset |
| `students.total_co2_saved_kg` | **current-cycle** running counter — zeroed on close-out |
| `monthly_archives` | snapshot of each closed month |

The per-month figures on the summary table are computed with
`GROUP BY YEAR(booked_at), MONTH(booked_at)` over `bookings`, so they stay
correct regardless of resets. `ArchiveDAO.closeOutMonth()` wraps the snapshot
and the counter reset in **one transaction** (a snapshot without the reset, or
the reverse, would leave the counter lying), and upserts on
`(student_id, year, month)` so re-closing a month refreshes rather than errors.

## Local environment

Installed via Homebrew: `openjdk`, `maven`, `tomcat` (11.0.25, port 8080),
`mysql` (running on **port 3307**, not the default 3306, because another
MySQL server was already using 3306 on this machine — see `/opt/homebrew/etc/my.cnf`).

- MySQL data: `green_mobility` database, app user `greenmob` / `greenmob_pw`
  (see `db/schema.sql` — also seeds 2 students and 6 slots)
- Demo login: `sid@woxsen.edu.in` / `password123`

Both services are registered with `brew services` so they restart automatically
on login. To manage them manually:

```bash
brew services start mysql
brew services start tomcat
brew services list
```

## Build & deploy (after making changes)

```bash
cd /Users/sid/Claude/pbl6-green-mobility
mvn clean package
cp target/green-mobility.war /opt/homebrew/opt/tomcat/libexec/webapps/green-mobility.war
```

Tomcat auto-redeploys when it sees the new WAR (watch
`/opt/homebrew/opt/tomcat/libexec/logs/catalina.<date>.log` for
"Deployment ... has finished").

App URL: **http://localhost:8080/green-mobility/**

## Runs fully offline

Every third-party asset is vendored under `src/main/webapp/vendor/`, so the app
renders correctly with **no internet connection** — safe for a viva room with
unreliable Wi-Fi. Verified: loading any page issues zero non-localhost requests.

```
vendor/
  bootstrap/        bootstrap.min.css, bootstrap.bundle.min.js   (5.3.3, MIT)
  bootstrap-icons/  bootstrap-icons.min.css + fonts/             (1.11.3, MIT)
  fonts/            plus-jakarta-sans.css + 2 woff2              (OFL 1.1)
```

Plus Jakarta Sans is a **variable** font: Google returned a byte-identical file
for every requested weight, so one file per subset (latin, latin-ext) covers
200-800 and the browser interpolates. Confirmed working by measuring text
advance widths across weights 400-800 — they increase monotonically, so weights
are real rather than synthesised.

To update a vendored library later, replace the file under `vendor/` — no
markup changes needed, since `header.jspf`/`footer.jspf` reference the paths
rather than a version-pinned URL.

## Resetting demo data

```bash
mysql -u greenmob -pgreenmob_pw --socket=/opt/homebrew/var/mysql/mysql.sock green_mobility \
  -e "DELETE FROM bookings; UPDATE vehicle_slots SET booked_count = 0; UPDATE students SET total_co2_saved_kg = 0;"
```

## What's left for the report / submission

- ER diagram (3 tables: `students`, `vehicle_slots`, `bookings` — FK from
  `bookings` to both)
- Screenshots of the browse → confirm → history flow (the same flow just verified above)
- A short write-up of the atomic-capacity-check design in `SlotDAO.tryReserveSeat()`
  — this is the answer to "how did you prevent overbooking?"
