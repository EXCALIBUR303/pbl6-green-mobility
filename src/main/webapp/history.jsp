<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.BookingDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.ArchiveDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.FeedbackDAO" %>
<%@ page import="com.woxsen.greenmobility.dao.PointsDAO" %>
<%@ page import="com.woxsen.greenmobility.model.Booking" %>
<%@ page import="com.woxsen.greenmobility.model.MonthlySummary" %>
<%@ page import="com.woxsen.greenmobility.model.PointEvent" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.math.RoundingMode" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.util.List" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    String pageTitle = "My Impact";
    List<Booking> bookings = new BookingDAO().getBookingsForStudent(loggedInStudent.getStudentId());

    // UI-only flag: whether each booking already has a feedback row, so the
    // timeline knows whether to offer "Rate this ride" or a submitted marker.
    FeedbackDAO feedbackDAO = new FeedbackDAO();
    for (Booking b : bookings) {
        if (b.isCompleted()) {
            b.setFeedbackSubmitted(feedbackDAO.hasFeedback(b.getBookingId()));
        }
    }
    request.setAttribute("bookings", bookings);

    List<PointEvent> pointEvents = new PointsDAO().getRecentEvents(loggedInStudent.getStudentId(), 8);
    request.setAttribute("pointEvents", pointEvents);

    request.setAttribute("areasToImprove", feedbackDAO.getAreasToImprove());

    List<MonthlySummary> monthly = new ArchiveDAO().getMonthlyBreakdown(loggedInStudent.getStudentId());
    request.setAttribute("monthly", monthly);

    LocalDate today = LocalDate.now();
    request.setAttribute("currentYear", today.getYear());
    request.setAttribute("currentMonth", today.getMonthValue());

    // Progress toward a 5 kg monthly goal, used by the ring.
    BigDecimal goal = new BigDecimal("5.00");
    BigDecimal saved = loggedInStudent.getTotalCo2SavedKg() == null
            ? BigDecimal.ZERO : loggedInStudent.getTotalCo2SavedKg();
    int goalPercent = saved.multiply(new BigDecimal("100"))
            .divide(goal, 0, RoundingMode.HALF_UP).intValue();
    if (goalPercent > 100) goalPercent = 100;
    request.setAttribute("goal", goal);
    request.setAttribute("goalPercent", goalPercent);

    // Same saving expressed as car-km avoided — more tangible than raw kg.
    BigDecimal kmAvoided = saved.divide(new BigDecimal("0.192"), 1, RoundingMode.HALF_UP);
    request.setAttribute("kmAvoided", kmAvoided);

    // Largest month scales the trend bars.
    BigDecimal maxMonth = BigDecimal.ZERO;
    for (MonthlySummary m : monthly) {
        if (m.getCo2SavedKg() != null && m.getCo2SavedKg().compareTo(maxMonth) > 0) {
            maxMonth = m.getCo2SavedKg();
        }
    }
    request.setAttribute("maxMonth", maxMonth.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ONE : maxMonth);
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/flash.jspf" %>

<h1 class="page-title text-forest mb-1">My impact</h1>
<p class="text-secondary mb-4">Every green trip you've taken, and the carbon it saved.</p>

<div class="row g-3 mb-4">
    <!-- Progress ring -->
    <div class="col-lg-4">
        <div class="card p-4 h-100 d-flex flex-column align-items-center justify-content-center">
            <div class="ring-wrap">
                <svg width="168" height="168" viewBox="0 0 168 168">
                    <defs>
                        <linearGradient id="ringGradient" x1="0" y1="0" x2="1" y2="1">
                            <stop offset="0%" stop-color="#40916c"/>
                            <stop offset="100%" stop-color="#b9e769"/>
                        </linearGradient>
                    </defs>
                    <circle class="ring-track" cx="84" cy="84" r="70" fill="none" stroke-width="13"/>
                    <circle class="ring-value" cx="84" cy="84" r="70" fill="none" stroke-width="13"
                            data-ring="${goalPercent}"/>
                </svg>
                <div class="ring-center">
                    <div class="num" data-count="${goalPercent}" data-suffix="%">0%</div>
                    <div class="cap">of ${goal} kg goal</div>
                </div>
            </div>
            <div class="text-center mt-3">
                <div class="fw-semibold" style="color: var(--forest-700);">
                    ${student.totalCo2SavedKg} kg saved this cycle
                </div>
                <div class="small" style="color: var(--ink-400);">
                    that's ~${kmAvoided} km of driving avoided
                </div>
            </div>
        </div>
    </div>

    <!-- Stat tiles + trend -->
    <div class="col-lg-8">
        <div class="row g-3 mb-3">
            <div class="col-sm-4">
                <div class="stat-tile h-100">
                    <div class="stat-value" data-count="${bookings.size()}">0</div>
                    <div class="stat-label">Green trips booked</div>
                    <i class="bi bi-signpost-split stat-glyph"></i>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="stat-tile tile-dark h-100">
                    <div class="stat-value" data-count="${kmAvoided}" data-decimals="1" data-suffix=" km">0</div>
                    <div class="stat-label">Car travel avoided</div>
                    <i class="bi bi-car-front stat-glyph"></i>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="stat-tile h-100">
                    <div class="stat-value" data-count="${student.pointsBalance}">0</div>
                    <div class="stat-label">Points earned</div>
                    <i class="bi bi-star-fill stat-glyph"></i>
                </div>
            </div>
        </div>

        <c:if test="${not empty monthly}">
            <div class="card p-4">
                <div class="section-label mb-3">
                    <i class="bi bi-bar-chart-line me-1"></i>Monthly trend
                </div>
                <div class="trend">
                    <c:forEach var="m" items="${monthly}" varStatus="st">
                        <c:if test="${st.index < 6}">
                            <div class="trend-col">
                                <span class="val">${m.co2SavedKg}</span>
                                <div class="trend-track">
                                    <div class="trend-bar ${m.year eq currentYear and m.month eq currentMonth ? 'is-current' : ''}"
                                         data-scale="${(m.co2SavedKg / maxMonth) * 100}"
                                         title="${m.label}: ${m.co2SavedKg} kg over ${m.tripCount} trips"></div>
                                </div>
                                <span class="lbl">${fn:substring(m.label, 0, 3)}</span>
                            </div>
                        </c:if>
                    </c:forEach>
                </div>
            </div>
        </c:if>
    </div>
</div>

<!-- Monthly summary + close-out -->
<c:if test="${not empty monthly}">
    <div class="card p-4 mb-4">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
            <span class="section-label"><i class="bi bi-calendar3 me-1"></i>Monthly summary</span>
            <span class="small" style="color: var(--ink-400);">
                Closing a month archives it and resets your running total
            </span>
        </div>

        <div class="table-responsive">
            <table class="table align-middle mb-0">
                <thead>
                <tr>
                    <th class="section-label">Month</th>
                    <th class="section-label">Trips</th>
                    <th class="section-label">CO<sub>2</sub></th>
                    <th class="section-label">Status</th>
                    <th></th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="m" items="${monthly}">
                    <tr>
                        <td class="fw-semibold">${m.label}</td>
                        <td style="color: var(--ink-600);">${m.tripCount}</td>
                        <td><span class="pill pill-eco">${m.co2SavedKg} kg</span></td>
                        <td>
                            <c:choose>
                                <c:when test="${m.archived}">
                                    <span class="pill pill-muted"><i class="bi bi-archive"></i>Closed out</span>
                                </c:when>
                                <c:when test="${m.year eq currentYear and m.month eq currentMonth}">
                                    <span class="pill pill-live"><span class="dot"></span>Current</span>
                                </c:when>
                                <c:otherwise>
                                    <span class="pill pill-muted">Open</span>
                                </c:otherwise>
                            </c:choose>
                        </td>
                        <td class="text-end">
                            <c:if test="${not m.archived}">
                                <form method="post" action="closeOutMonth.jsp" class="d-inline" data-busy
                                      onsubmit="return confirm('Close out ${m.label}? Its ${m.co2SavedKg} kg will be archived and your running total resets to 0. Your booking history is kept.');">
                                    <input type="hidden" name="year" value="${m.year}">
                                    <input type="hidden" name="month" value="${m.month}">
                                    <button type="submit" class="btn btn-sm btn-outline-secondary">
                                        <i class="bi bi-archive me-1"></i>Close out
                                    </button>
                                </form>
                            </c:if>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div>
    </div>
</c:if>

<!-- Booking timeline -->
<div class="card p-4">
    <span class="section-label d-block mb-3"><i class="bi bi-list-ul me-1"></i>All bookings</span>

    <c:choose>
        <c:when test="${empty bookings}">
            <div class="empty-state">
                <div class="glyph"><i class="bi bi-calendar2-x"></i></div>
                <p class="text-secondary mt-3 mb-3">You haven't booked any green trips yet.</p>
                <a href="availability.jsp" class="btn btn-primary">
                    <i class="bi bi-calendar2-week me-1"></i>Browse available slots
                </a>
            </div>
        </c:when>
        <c:otherwise>
            <div class="timeline" data-reveal>
                <c:forEach var="b" items="${bookings}">
                    <div class="tl-item">
                        <div class="d-flex flex-wrap justify-content-between align-items-start gap-2">
                            <div class="min-w-0">
                                <c:set var="bp" value="${fn:split(b.route, '->')}"/>
                                <div class="journey mb-1">
                                    <span class="stop">${fn:trim(bp[0])}</span>
                                    <span class="track" style="min-width:24px;"></span>
                                    <span class="stop">${fn:trim(bp[1])}</span>
                                </div>
                                <div class="meta-row">
                                    <span class="meta">
                                        <i class="bi ${b.vehicleType eq 'Shared Bike' ? 'bi-bicycle' : 'bi-bus-front'}"></i>
                                        ${b.vehicleType}
                                    </span>
                                    <span class="meta">
                                        <i class="bi bi-clock"></i>
                                        <fmt:formatDate value="${b.slotTime}" pattern="dd MMM, hh:mm a"/>
                                    </span>
                                    <span class="meta"><i class="bi bi-signpost-2"></i>${b.distanceKm} km</span>
                                </div>
                            </div>
                            <div class="d-flex flex-column align-items-end gap-2">
                                <c:choose>
                                    <c:when test="${b.cancelled}">
                                        <span class="pill pill-muted"><i class="bi bi-x-circle"></i>Cancelled</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="pill pill-eco">
                                            <i class="bi bi-cloud-check"></i>${b.co2SavedKg} kg
                                        </span>
                                    </c:otherwise>
                                </c:choose>
                                <c:if test="${b.rewardRedeemed}">
                                    <span class="pill pill-soon"><i class="bi bi-gift-fill"></i>Free ride</span>
                                </c:if>

                                <c:if test="${b.cancellable}">
                                    <button type="button" class="btn btn-sm btn-outline-danger"
                                            data-bs-toggle="modal" data-bs-target="#cancelModal"
                                            data-booking-id="${b.bookingId}">
                                        <i class="bi bi-x-lg me-1"></i>Cancel
                                    </button>
                                </c:if>

                                <c:if test="${b.completed and not b.feedbackSubmitted}">
                                    <button type="button" class="btn btn-sm btn-outline-success"
                                            data-bs-toggle="modal" data-bs-target="#rateModal"
                                            data-booking-id="${b.bookingId}">
                                        <i class="bi bi-star me-1"></i>Rate this ride
                                    </button>
                                </c:if>
                                <c:if test="${b.completed and b.feedbackSubmitted}">
                                    <span class="pill pill-muted"><i class="bi bi-check2"></i>Rated</span>
                                </c:if>
                            </div>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<div class="row g-3 mt-1">
    <!-- Recent points activity — the append-only ledger, made visible -->
    <div class="col-lg-6">
        <div class="card p-4 h-100">
            <span class="section-label d-block mb-3">
                <i class="bi bi-list-columns-reverse me-1"></i>Recent points activity
            </span>
            <c:choose>
                <c:when test="${empty pointEvents}">
                    <p class="text-secondary small mb-0">
                        No points yet &mdash; they're awarded once a booked ride's window passes.
                    </p>
                </c:when>
                <c:otherwise>
                    <div class="d-flex flex-column gap-2">
                        <c:forEach var="e" items="${pointEvents}">
                            <div class="d-flex justify-content-between align-items-center gap-2">
                                <div class="min-w-0">
                                    <div class="small fw-semibold text-truncate">${e.reason}</div>
                                    <div class="small" style="color: var(--ink-400);">
                                        <fmt:formatDate value="${e.createdAt}" pattern="dd MMM, hh:mm a"/>
                                    </div>
                                </div>
                                <span class="pill ${e.points ge 0 ? 'pill-eco' : 'pill-full'} flex-shrink-0">
                                    ${e.points ge 0 ? '+' : ''}${e.points} pts
                                </span>
                            </div>
                        </c:forEach>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <!-- Campus-wide feedback signal, fed by both post-ride and pre-cancellation forms -->
    <div class="col-lg-6">
        <div class="card p-4 h-100">
            <span class="section-label d-block mb-3">
                <i class="bi bi-megaphone me-1"></i>Areas to improve (campus-wide)
            </span>
            <c:choose>
                <c:when test="${empty areasToImprove}">
                    <p class="text-secondary small mb-0">No feedback submitted yet.</p>
                </c:when>
                <c:otherwise>
                    <div class="d-flex flex-column gap-2">
                        <c:forEach var="a" items="${areasToImprove}">
                            <div class="d-flex justify-content-between align-items-center gap-2">
                                <span class="small fw-semibold">${a.category}</span>
                                <div class="d-flex align-items-center gap-2">
                                    <c:if test="${not empty a.avgRating}">
                                        <span class="pill pill-muted">
                                            <i class="bi bi-star-fill" style="color:var(--amber);"></i>
                                            <fmt:formatNumber value="${a.avgRating}" maxFractionDigits="1"/>
                                        </span>
                                    </c:if>
                                    <span class="pill pill-eco">${a.mentions} mentions</span>
                                </div>
                            </div>
                        </c:forEach>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
</div>

<%-- Shared modal: pre-cancellation feedback is optional and lightweight on
     purpose -- a student who just wants out shouldn't be blocked by a form. --%>
<div class="modal fade" id="cancelModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <form method="post" action="cancelBooking.jsp" data-busy>
        <div class="modal-header">
          <h5 class="modal-title"><i class="bi bi-x-circle me-2"></i>Cancel this ride?</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" name="bookingId" class="modal-booking-id">
          <p class="text-secondary small mb-3">
              Your seat is released immediately for other students. Mind telling us why? (optional)
          </p>
          <select class="form-select mb-2" name="category">
              <option value="">Prefer not to say</option>
              <option value="SCHEDULE_CHANGE">My schedule changed</option>
              <option value="FOUND_ALTERNATIVE">Found another way to travel</option>
              <option value="BOOKED_BY_MISTAKE">Booked by mistake</option>
              <option value="VEHICLE_CONCERN">Concern about the vehicle or route</option>
              <option value="OTHER">Other</option>
          </select>
          <textarea class="form-control" name="comment" rows="2" placeholder="Anything else? (optional)"></textarea>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Keep booking</button>
          <button type="submit" class="btn btn-danger"><i class="bi bi-x-lg me-1"></i>Cancel ride</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%-- Shared modal: post-ride rating + comment, only offered once per booking
     (FeedbackDAO.hasFeedback / feedbackSubmitted gate this button). --%>
<div class="modal fade" id="rateModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <form method="post" action="submitFeedback.jsp" data-busy>
        <div class="modal-header">
          <h5 class="modal-title"><i class="bi bi-star me-2"></i>Rate this ride</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" name="bookingId" class="modal-booking-id">
          <div class="mb-3">
              <label class="form-label small fw-semibold">How was it?</label>
              <select class="form-select" name="rating" required>
                  <option value="5">★★★★★ Excellent</option>
                  <option value="4">★★★★ Good</option>
                  <option value="3" selected>★★★ Okay</option>
                  <option value="2">★★ Poor</option>
                  <option value="1">★ Very poor</option>
              </select>
          </div>
          <div class="mb-3">
              <label class="form-label small fw-semibold">What could improve?</label>
              <select class="form-select" name="category" required>
                  <option value="VEHICLE_CONDITION">Vehicle condition</option>
                  <option value="PUNCTUALITY">Punctuality</option>
                  <option value="DRIVER_STAFF">Driver / staff</option>
                  <option value="ROUTE_COVERAGE">Route coverage</option>
                  <option value="BOOKING_EXPERIENCE">Booking experience</option>
                  <option value="OTHER">Other</option>
              </select>
          </div>
          <textarea class="form-control" name="comment" rows="2" placeholder="Any comments? (optional)"></textarea>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Skip</button>
          <button type="submit" class="btn btn-primary"><i class="bi bi-send me-1"></i>Submit feedback</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
