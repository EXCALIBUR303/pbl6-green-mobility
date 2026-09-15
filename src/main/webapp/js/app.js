/* Campus Green Mobility — client-side interaction layer.
 *
 * Progressive by design: every feature here enhances markup the server already
 * rendered, so the pages stay readable and usable if this file fails to load.
 *
 * All motion is driven by motion.dev and nothing else. There is deliberately no
 * second animation engine and no CSS-keyframe fallback — when motion.dev is
 * missing, or the visitor prefers reduced motion, animated things snap straight
 * to their final state rather than animating by some other route.
 *
 * Kept in a .js file (not inline in a .jsp) so JS template literals can use
 * ${...} without the JSP EL engine trying to evaluate them first.
 */
(function () {
  "use strict";

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------------------------------------------------------------- utils */

  function $(sel, root) { return (root || document).querySelector(sel); }
  function $$(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  /* ---------------------------------------------------------- motion.dev */

  /*
   * The vendored bundle is motion.dev v13's standalone UMD build, which exposes
   * a NAMESPACE object on window.Motion — Motion.animate(), Motion.stagger(),
   * Motion.hover(). The `import { motion } from "motion/react"` form in most of
   * the docs is the React entry point; it needs a bundler and does not apply to
   * a plain <script> page like this one.
   *
   * Three differences from the anime.js code this replaced, all of them easy to
   * get wrong:
   *   - duration and delay are in SECONDS here, not milliseconds
   *   - stagger() returns a function called as (index, total), not (el, i, arr)
   *   - animating any transform component (scale, y, ...) REWRITES the whole
   *     inline transform, so a CSS translate on the same element is discarded.
   *     Verified directly against this build; spawnRipple() depends on it.
   */
  var M = window.Motion;
  var hasMotion = !!(M && typeof M.animate === "function");

  // The single gate for "should this actually move, or just be in its end state".
  var animates = hasMotion && !reduceMotion;

  // Drops the class that lets CSS hide pre-entrance elements. Once this is gone
  // the page is visible no matter what any animation did or failed to do.
  function releaseMotionGate() {
    document.documentElement.classList.remove("js-anim");
  }

  // Hands an element back to the stylesheet after motion.dev has finished
  // writing inline values to it. Without this the inline transform would
  // permanently outrank .btn-primary's CSS hover lift.
  function clearInline(els) {
    els.forEach(function (el) {
      el.style.opacity = "";
      el.style.transform = "";
      el.style.transition = "";
    });
  }

  /*
   * Several elements we animate in also carry a CSS `transition` on transform
   * (.slot-card and .btn both do, for their hover lift). motion.dev writes the
   * transform inline on every frame, and an inline write DOES trigger a CSS
   * transition — so the two would fight and visibly smear the entrance. The old
   * CSS-keyframe version never had this problem, because a CSS animation
   * overrides a transition on the same property; a JS-driven one does not.
   * Suppress the transition for the duration, then clearInline() restores it.
   */
  function suppressTransition(els) {
    els.forEach(function (el) { el.style.transition = "none"; });
  }

  /* ------------------------------------------------- animated number count */

  function finalCount(el, target) {
    var decimals = parseInt(el.dataset.decimals || "0", 10);
    return target.toFixed(decimals) + (el.dataset.suffix || "");
  }

  function initCounters() {
    var nodes = $$("[data-count]").filter(function (el) {
      return !isNaN(parseFloat(el.dataset.count));
    });
    if (!nodes.length) return;

    if (!animates) {
      nodes.forEach(function (el) {
        el.textContent = finalCount(el, parseFloat(el.dataset.count));
      });
      return;
    }

    // Hold the figures back until the hero's stat block has actually arrived on
    // the login page; elsewhere there is no entrance sequence to wait for.
    var lead = $('[data-anim="hero"]') ? 0.72 : 0.14;

    // stagger() hands back a function motion.dev would normally call for us. We
    // are tweening a plain number per element rather than the elements
    // themselves, so we call it ourselves — signature is (index, total).
    var offset = M.stagger(0.17, { startDelay: lead });

    nodes.forEach(function (el, i) {
      var target = parseFloat(el.dataset.count);
      var decimals = parseInt(el.dataset.decimals || "0", 10);
      var suffix = el.dataset.suffix || "";

      M.animate(0, target, {
        duration: 1.15,
        ease: "easeOut",
        delay: offset(i, nodes.length),
        onUpdate: function (v) {
          el.textContent = v.toFixed(decimals) + suffix;
        },
        onComplete: function () {
          el.textContent = finalCount(el, target);
        }
      });

      // motion.dev is rAF-driven, and rAF is suspended in a background tab — so
      // keep the guarantee that the real figure lands even if the animation
      // never got a single frame.
      setTimeout(function () {
        el.textContent = finalCount(el, target);
      }, (lead + 1.4) * 1000);
    });
  }

  /* ----------------------------------------------------- bars & ring fills */

  function pct(value) {
    return Math.max(0, Math.min(100, parseFloat(value) || 0));
  }

  /*
   * Capacity meters, leaderboard bars, monthly trend columns and the impact
   * progress ring. Each has a setTimeout that force-writes the settled value:
   * rAF is suspended while a tab is hidden, which would otherwise leave every
   * bar stuck at zero for anyone who opens the page in a background tab.
   */
  function animateFills() {
    var bars = $$("[data-fill]");
    var scales = $$("[data-scale]");

    // Dash geometry has to be set up front so the ring's resting state is right
    // before anything animates.
    var rings = $$("[data-ring]").map(function (el) {
      var r = parseFloat(el.getAttribute("r"));
      var circumference = 2 * Math.PI * r;
      el.style.strokeDasharray = circumference;
      el.style.strokeDashoffset = circumference;
      return { el: el, circumference: circumference };
    });

    function settle() {
      bars.forEach(function (el) { el.style.width = pct(el.dataset.fill) + "%"; });
      scales.forEach(function (el) {
        el.style.transform = "scaleY(" + (pct(el.dataset.scale) / 100) + ")";
      });
      rings.forEach(function (ring) {
        ring.el.style.strokeDashoffset = ring.circumference * (1 - pct(ring.el.dataset.ring) / 100);
      });
    }

    if (!animates) { settle(); return; }

    bars.forEach(function (el) {
      M.animate(el, { width: ["0%", pct(el.dataset.fill) + "%"] },
        { duration: 1.1, delay: 0.12, ease: "easeOut" });
    });

    scales.forEach(function (el) {
      M.animate(el, { scaleY: [0, pct(el.dataset.scale) / 100] },
        { duration: 1, delay: 0.12, ease: "easeOut" });
    });

    rings.forEach(function (ring) {
      M.animate(ring.el,
        { strokeDashoffset: [ring.circumference, ring.circumference * (1 - pct(ring.el.dataset.ring) / 100)] },
        { duration: 1.4, delay: 0.12, ease: "easeOut" });
    });

    setTimeout(settle, 1800);
  }

  /* ------------------------------------------------- departure countdowns */

  function humanGap(ms) {
    if (ms <= 0) return null;
    var mins = Math.floor(ms / 60000);
    var days = Math.floor(mins / 1440);
    var hours = Math.floor((mins % 1440) / 60);
    var m = mins % 60;

    if (days > 0) return "in " + days + "d " + hours + "h";
    if (hours > 0) return "in " + hours + "h " + m + "m";
    return "in " + m + "m";
  }

  function tickCountdowns() {
    var nodes = $$("[data-departs]");
    if (!nodes.length) return;

    nodes.forEach(function (el) {
      var when = parseInt(el.dataset.departs, 10);
      if (isNaN(when)) return;

      var gap = when - Date.now();
      var label = humanGap(gap);

      if (label === null) {
        el.textContent = "departed";
        el.classList.add("pill-muted");
        el.classList.remove("pill-eco", "pill-soon");
        return;
      }

      el.textContent = label;
      // Highlight anything leaving within the hour.
      if (gap < 3600000) {
        el.classList.add("pill-soon");
        el.classList.remove("pill-eco");
      }
    });
  }

  /* --------------------------------------------------- live indicator dot */

  // Replaces the old CSS `pulse-dot` keyframes.
  function initPulseDots() {
    if (!animates) return;
    var dots = $$(".pill-live .dot");
    if (!dots.length) return;

    M.animate(dots, { opacity: [1, 0.35, 1], scale: [1, 0.8, 1] },
      { duration: 1.9, repeat: Infinity, ease: "easeInOut" });
  }

  /* ------------------------------------------------------- hero backdrop */

  // Replaces the old CSS `drift` keyframes on the two login hero orbs.
  function initOrbs() {
    if (!animates) return;

    var o1 = $(".hero-orb.o1");
    var o2 = $(".hero-orb.o2");

    if (o1) {
      M.animate(o1, { x: [0, 26, 0], y: [0, -22, 0], scale: [1, 1.09, 1] },
        { duration: 17, repeat: Infinity, ease: "easeInOut" });
    }
    if (o2) {
      // Mirrored direction and a different period so the two never sync up.
      M.animate(o2, { x: [0, -26, 0], y: [0, 22, 0], scale: [1, 1.09, 1] },
        { duration: 21, repeat: Infinity, ease: "easeInOut" });
    }
  }

  /* ------------------------------------------------------ browse filtering */

  function initFilters() {
    var search = $("#slotSearch");
    var chips = $$("[data-filter]");
    var cards = $$("[data-slot]");
    var emptyMsg = $("#noMatches");
    if (!cards.length) return;

    var activeType = "all";

    function apply() {
      var q = (search && search.value || "").trim().toLowerCase();
      var shown = 0;

      cards.forEach(function (card) {
        var type = card.dataset.type || "";
        var haystack = (card.dataset.search || "").toLowerCase();

        var matchesType = activeType === "all" || type === activeType;
        var matchesText = !q || haystack.indexOf(q) !== -1;
        var show = matchesType && matchesText;

        card.style.display = show ? "" : "none";
        if (show) shown++;
      });

      if (emptyMsg) emptyMsg.style.display = shown === 0 ? "" : "none";
    }

    chips.forEach(function (chip) {
      chip.addEventListener("click", function () {
        chips.forEach(function (c) { c.classList.remove("active"); });
        chip.classList.add("active");
        activeType = chip.dataset.filter;
        apply();
      });
    });

    if (search) {
      search.addEventListener("input", apply);
      // Let Esc clear the box while typing.
      search.addEventListener("keydown", function (e) {
        if (e.key === "Escape") { search.value = ""; apply(); }
      });
    }
  }

  /* ------------------------------------------------------------- toasts */

  function ensureStack() {
    var stack = $(".toast-stack");
    if (!stack) {
      stack = document.createElement("div");
      stack.className = "toast-stack";
      document.body.appendChild(stack);
    }
    return stack;
  }

  // Entrance and exit were CSS `toast-in` / `toast-out` keyframes; motion.dev
  // now owns both, which also means the exit can await its own completion
  // instead of a setTimeout racing the stylesheet.
  function toast(message, isError) {
    var stack = ensureStack();
    var el = document.createElement("div");
    el.className = "app-toast" + (isError ? " err" : "");
    el.setAttribute("role", isError ? "alert" : "status");

    var icon = document.createElement("i");
    icon.className = "ico bi " + (isError ? "bi-exclamation-triangle-fill" : "bi-check-circle-fill");

    var body = document.createElement("div");
    body.textContent = message;

    el.appendChild(icon);
    el.appendChild(body);
    stack.appendChild(el);

    function dismiss() {
      if (!animates) { el.remove(); return; }
      M.animate(el, { opacity: 0, x: 26 }, { duration: 0.3, ease: "easeIn" })
        .finished.then(function () { el.remove(); });
      // Unconditional backstop: if the tab is hidden when the auto-dismiss timer
      // fires, the fade never runs and .finished never resolves. remove() on an
      // already-detached node is a no-op, so running both paths is safe.
      setTimeout(function () { el.remove(); }, 400);
    }

    if (animates) {
      M.animate(el, { opacity: [0, 1], x: [26, 0], scale: [0.97, 1] },
        { duration: 0.45, ease: "backOut" });
    }

    setTimeout(dismiss, 5200);
  }

  function initFlash() {
    var flash = $("#flash");
    if (!flash) return;
    var msg = flash.dataset.msg;
    if (!msg) return;

    var isError = flash.dataset.status === "error";
    toast(msg, isError);

    if (!isError && /booked/i.test(msg)) confetti();
  }

  /* ----------------------------------------------------------- confetti */

  /*
   * Canvas particles, so there is no DOM to hand to motion.dev — but the clock
   * driving them is a motion.dev tween rather than a bare rAF loop, which keeps
   * a single timing source for the whole app and gives us cancellation for free.
   */
  function confetti() {
    if (!animates) return;

    var canvas = document.createElement("canvas");
    canvas.id = "confetti-canvas";
    document.body.appendChild(canvas);

    var ctx = canvas.getContext("2d");
    var dpr = window.devicePixelRatio || 1;

    function size() {
      canvas.width = window.innerWidth * dpr;
      canvas.height = window.innerHeight * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    }
    size();

    var colors = ["#95d5b2", "#b9e769", "#40916c", "#2d6a4f", "#d8f3dc"];
    var pieces = [];
    for (var i = 0; i < 90; i++) {
      pieces.push({
        x: Math.random() * window.innerWidth,
        y: -20 - Math.random() * window.innerHeight * 0.35,
        w: 6 + Math.random() * 6,
        h: 8 + Math.random() * 8,
        vy: 1.8 + Math.random() * 2.6,
        vx: -1 + Math.random() * 2,
        rot: Math.random() * Math.PI,
        vr: -0.12 + Math.random() * 0.24,
        color: colors[Math.floor(Math.random() * colors.length)]
      });
    }

    var tween = null;

    function teardown() {
      // Stop the tween first: if the timeout below fired because the tab was
      // hidden, the tween is still live and would keep calling onUpdate against
      // a canvas that no longer has a context in the document.
      if (tween) { try { tween.stop(); } catch (e) { /* already finished */ } }
      canvas.remove();
      window.removeEventListener("resize", size);
    }

    window.addEventListener("resize", size);

    // Tween elapsed milliseconds so the particle physics below is unchanged.
    tween = M.animate(0, 3200, {
      duration: 3.2,
      ease: "linear",
      onUpdate: function (elapsed) {
        ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
        ctx.globalAlpha = elapsed > 2200 ? Math.max(0, 1 - (elapsed - 2200) / 900) : 1;

        pieces.forEach(function (p) {
          p.x += p.vx;
          p.y += p.vy;
          p.rot += p.vr;

          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rot);
          ctx.fillStyle = p.color;
          ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
          ctx.restore();
        });
      },
      onComplete: teardown
    });

    // If the tab is hidden the tween never advances, so guarantee the canvas and
    // its resize listener are cleaned up regardless.
    setTimeout(teardown, 6000);
  }

  /* ------------------------------------------- submit busy state feedback */

  function initBusyButtons() {
    $$("form[data-busy]").forEach(function (form) {
      form.addEventListener("submit", function () {
        var btn = form.querySelector('button[type="submit"]');
        if (!btn || btn.classList.contains("is-busy")) return;
        btn.classList.add("is-busy");
        btn.insertAdjacentHTML("afterbegin", '<span class="spinner"></span>');

        // Replaces the old CSS `spin` keyframes.
        var spinner = btn.querySelector(".spinner");
        if (spinner && animates) {
          M.animate(spinner, { rotate: 360 },
            { duration: 0.6, repeat: Infinity, ease: "linear" });
        }
      });
    });
  }

  /* --------------------------------------------------- staggered reveals */

  /*
   * Replaces the old `.reveal` class + `reveal-in` keyframes + inline --i index.
   * The starting opacity is written synchronously here rather than left to
   * motion.dev's first frame, so there is no chance of a one-frame flash of the
   * settled state before the entrance begins.
   */
  function initReveal() {
    var groups = $$("[data-reveal]");
    if (!groups.length) return;

    groups.forEach(function (group) {
      var children = Array.prototype.slice.call(group.children);
      if (!children.length || !animates) return;

      children.forEach(function (c) { c.style.opacity = "0"; });
      suppressTransition(children);

      M.animate(children, { opacity: [0, 1], y: [14, 0] },
        { duration: 0.55, ease: "easeOut", delay: M.stagger(0.055) })
        .finished.then(function () { clearInline(children); });

      // These children start at opacity 0, and motion.dev is rAF-driven — so in a
      // background tab .finished never resolves and the whole list would stay
      // invisible. Force the settled state well past the last staggered item.
      setTimeout(function () { clearInline(children); },
        (0.55 + 0.055 * children.length + 0.4) * 1000);
    });
  }

  /* ------------------------------------------------------ login entrance */

  function settleLogin(els) {
    releaseMotionGate();
    clearInline(els);
  }

  function initLoginMotion() {
    var hero = $$('[data-anim="hero"]');
    var card = $$('[data-anim="card"]');
    var all = hero.concat(card);

    // Any page without these hooks was never hidden — just open the gate.
    if (!all.length) { releaseMotionGate(); return; }

    // The stylesheet's prefers-reduced-motion block cannot stop motion.dev,
    // which writes inline values on a rAF loop and never consults CSS. So the
    // decision has to be made here.
    if (!animates) { settleLogin(all); return; }

    // The submit button in the card group carries .btn's transform transition,
    // which would fight motion.dev's per-frame inline writes.
    suppressTransition(all);

    // The hero leads by a beat and the form follows on a tighter stagger — the
    // form is the part someone actually came here to use, so it must not feel
    // like it is being withheld. Whole sequence is done inside ~1s.
    var a = M.animate(hero, { opacity: [0, 1], y: [18, 0] },
      { duration: 0.62, ease: "easeOut", delay: M.stagger(0.07) });

    var b = M.animate(card, { opacity: [0, 1], y: [14, 0] },
      { duration: 0.62, ease: "easeOut", delay: M.stagger(0.055, { startDelay: 0.09 }) });

    Promise.all([a.finished, b.finished]).then(function () { settleLogin(all); });

    // Belt-and-braces against a rAF-starved background tab: the inline <head>
    // failsafe would eventually reveal the page anyway, but this also strips the
    // half-finished inline styles.
    setTimeout(function () { settleLogin(all); }, 2600);
  }

  /* ---------------------------------------------------- press & focus feel */

  function spawnRipple(btn, x, y) {
    var rect = btn.getBoundingClientRect();
    // Large enough to still cover the button when struck near a corner.
    var size = Math.max(rect.width, rect.height) * 2.2;

    var ink = document.createElement("span");
    ink.className = "ripple";
    ink.style.width = size + "px";
    ink.style.height = size + "px";
    // Centred with JS arithmetic rather than a CSS translate(-50%,-50%), because
    // animating `scale` rewrites the element's whole inline transform and would
    // drop the translate. Confirmed against this motion.dev build.
    ink.style.left = (x - rect.left - size / 2) + "px";
    ink.style.top = (y - rect.top - size / 2) + "px";
    btn.appendChild(ink);

    M.animate(ink, { scale: [0, 1], opacity: [0.5, 0] },
      { duration: 0.62, ease: "easeOut" })
      .finished.then(function () { ink.remove(); });

    // Same rAF-suspension backstop as the toast: without this, ink nodes pile up
    // inside the button when a press happens just before the tab is hidden.
    setTimeout(function () { ink.remove(); }, 900);
  }

  function initRipples() {
    if (!animates) return;

    $$("[data-ripple]").forEach(function (btn) {
      btn.addEventListener("pointerdown", function (e) {
        spawnRipple(btn, e.clientX, e.clientY);
      });

      // Keyboard activation fires no pointer event, so ripple from the centre.
      btn.addEventListener("click", function (e) {
        if (e.detail !== 0) return; // a real pointer click already rippled
        var r = btn.getBoundingClientRect();
        spawnRipple(btn, r.left + r.width / 2, r.top + r.height / 2);
      });
    });
  }

  /*
   * Pops the leading icon while a field is focused. Deliberately targets the
   * icon and not the input or its wrapper: transforming the field itself risks
   * shifting where the browser anchors autofill and password-manager popovers,
   * and the border/ring is already handled by .form-control:focus in CSS.
   */
  function initFieldFocus() {
    if (!animates) return;

    $$(".input-group .form-control").forEach(function (input) {
      var group = input.closest(".input-group");
      var icon = group && group.querySelector(".input-group-text i");
      if (!icon) return;

      input.addEventListener("focus", function () {
        M.animate(icon, { scale: 1.18 }, { duration: 0.32, ease: "backOut" });
      });
      input.addEventListener("blur", function () {
        M.animate(icon, { scale: 1 }, { duration: 0.26, ease: "easeOut" });
      });
    });
  }

  /* ------------------------------------------------------ booking modals */

  /*
   * <main> is `position: relative` with its own z-index (so the navbar
   * dropdown can layer above it — see style.css), which makes it a stacking
   * context. Every .modal in this app is authored inside <main>, but
   * Bootstrap always appends .modal-backdrop as a plain sibling of <body>,
   * outside that stacking context — so the backdrop's z-index gets compared
   * against <main> as a WHOLE (z-index: 1), not against the modal's own
   * z-index 1055 nested inside it, and wins. Moving each modal to be a direct
   * child of <body> before it's ever shown puts it in the same root stacking
   * context as the backdrop, where Bootstrap's own z-index values (1055 over
   * 1050) resolve correctly. Confirmed via elementFromPoint: before this fix,
   * the element under a modal button's own coordinates was the backdrop, not
   * the button.
   */
  function initBookingModals() {
    $$(".modal").forEach(function (modal) {
      if (modal.parentNode !== document.body) {
        document.body.appendChild(modal);
      }
      modal.addEventListener("show.bs.modal", function (e) {
        var btn = e.relatedTarget;
        var id = btn && btn.getAttribute("data-booking-id");
        var field = modal.querySelector(".modal-booking-id");
        if (field && id) field.value = id;
      });
    });
  }

  /* -------------------------------------------- auto post-ride feedback */

  /*
   * A completed ride with no feedback yet pops this modal once per booking
   * per browser (localStorage-gated) rather than waiting for the student to
   * notice History's "Rate this ride" button. The flag is set the moment the
   * modal is SHOWN, not only on submit — "Maybe later" should stop the nag
   * too, since the button on History still offers a way to rate it later.
   */
  function initAutoFeedback() {
    var trigger = document.getElementById("autoFeedbackTrigger");
    var modalEl = document.getElementById("autoFeedbackModal");
    if (!trigger || !modalEl || !window.bootstrap) return;

    var key = "fb_prompted_" + trigger.dataset.bookingId;
    try {
      if (localStorage.getItem(key)) return;
      localStorage.setItem(key, "1");
    } catch (e) {
      // Storage unavailable (private mode, etc.) — fall through and show it
      // anyway rather than silently never prompting.
    }

    new window.bootstrap.Modal(modalEl).show();
  }

  /* ------------------------------------------------ live seat polling */

  /*
   * Re-renders one slot card's capacity block to mirror availability.jsp's
   * own <c:choose> exactly, so a card updated by a poll looks identical to
   * one rendered fresh by the server.
   */
  function renderSlotCapacity(card, s) {
    var capacityEl = card.querySelector(".capacity");
    var statusSlot = capacityEl && capacityEl.querySelector(".d-flex");
    var fillEl = capacityEl && capacityEl.querySelector(".fill");
    var actionEl = card.querySelector(".slot-action");
    if (!capacityEl || !statusSlot || !fillEl || !actionEl) return;

    capacityEl.classList.remove("full", "warn");
    if (s.remainingCapacity <= 0) {
      capacityEl.classList.add("full");
      statusSlot.innerHTML = '<span class="pill pill-full"><i class="bi bi-slash-circle"></i>Full</span>';
    } else if (s.almostFull) {
      capacityEl.classList.add("warn");
      statusSlot.innerHTML = '<span class="pill pill-soon">Only ' + s.remainingCapacity + ' left</span>';
    } else {
      statusSlot.innerHTML = '<small style="color: var(--ink-600);"><strong>' + s.remainingCapacity +
        '</strong> of ' + s.capacity + ' free</small>';
    }

    fillEl.dataset.fill = s.fillPercent;
    if (animates) {
      M.animate(fillEl, { width: [fillEl.style.width || "0%", s.fillPercent + "%"] },
        { duration: 0.5, ease: "easeOut" });
    } else {
      fillEl.style.width = s.fillPercent + "%";
    }

    card.classList.toggle("is-full", s.remainingCapacity <= 0);

    actionEl.innerHTML = s.remainingCapacity > 0
      ? '<a class="btn btn-primary px-4" href="confirmBooking.jsp?slotId=' + s.slotId +
        '">Book <i class="bi bi-arrow-right ms-1"></i></a>'
      : '<button class="btn btn-outline-secondary px-4" disabled>Full</button>';
  }

  /*
   * Polls the browse page's own slot data every few seconds so a seat filling
   * up (or a cancellation freeing one back up) shows up for every browser
   * looking at it, not just the one that made the change. A no-op on every
   * other page — there's simply nothing matching [data-slot-id] there.
   */
  function initLivePolling() {
    var cards = $$("[data-slot-id]");
    if (!cards.length || typeof fetch !== "function") return;

    var byId = {};
    cards.forEach(function (card) { byId[card.dataset.slotId] = card; });

    function poll() {
      fetch("slotStatus.jsp", { cache: "no-store" })
        .then(function (r) { return r.ok ? r.json() : null; })
        .then(function (data) {
          if (!data) return;
          data.forEach(function (s) {
            var card = byId[s.slotId];
            if (card) renderSlotCapacity(card, s);
          });
        })
        .catch(function () { /* offline or a hiccup — the next tick retries */ });
    }

    setInterval(poll, 8000);
  }

  /* ---------------------------------------------------------------- boot */

  document.addEventListener("DOMContentLoaded", function () {
    initLoginMotion();
    initReveal();
    initCounters();
    animateFills();
    initOrbs();
    initPulseDots();
    initFilters();
    initFlash();
    initBusyButtons();
    initRipples();
    initFieldFocus();
    initBookingModals();
    initAutoFeedback();
    initLivePolling();

    tickCountdowns();
    setInterval(tickCountdowns, 30000);
  });
})();
