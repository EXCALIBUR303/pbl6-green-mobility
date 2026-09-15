<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.SlotDAO" %>
<%@ page import="java.util.List" %>
<%@ page import="com.woxsen.greenmobility.model.VehicleSlot" %>
<%@ page import="com.woxsen.greenmobility.util.CookieUtil" %>
<%@ page import="java.util.ArrayList" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    String pageTitle = "Browse Slots";
    SlotDAO slotDAO = new SlotDAO();
    List<VehicleSlot> slots = slotDAO.getUpcomingSlots();
    request.setAttribute("slots", slots);

    // Counts drive the numbers shown on the filter chips.
    int shuttleCount = 0, bikeCount = 0;
    for (VehicleSlot s : slots) {
        if ("Shared Bike".equals(s.getVehicleType())) bikeCount++; else shuttleCount++;
    }
    request.setAttribute("shuttleCount", shuttleCount);
    request.setAttribute("bikeCount", bikeCount);

    // COOKIE: rebuild the "recently viewed" trail left by earlier visits.
    // Ids come from the client, so each one is re-fetched and null-checked.
    List<VehicleSlot> recentSlots = new ArrayList<>();
    for (Integer recentId : CookieUtil.readRecentSlotIds(request)) {
        VehicleSlot recent = slotDAO.findById(recentId);
        if (recent != null) {
            recentSlots.add(recent);
        }
    }
    request.setAttribute("recentSlots", recentSlots);
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<%@ include file="/WEB-INF/jspf/flash.jspf" %>

<div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
    <div>
        <span class="pill pill-live mb-2"><span class="dot"></span> Live availability</span>
        <h1 class="page-title text-forest mb-1">Find your next green ride</h1>
        <p class="text-secondary mb-0">
            Book a shuttle or bike instead of a private trip &mdash; we'll track the CO<sub>2</sub> you save.
        </p>
    </div>
    <a href="history.jsp" class="btn btn-outline-success">
        <i class="bi bi-graph-up-arrow me-1"></i>My impact
    </a>
</div>

<c:if test="${not empty recentSlots}">
    <div class="recent-strip mb-4">
        <div class="d-flex align-items-center gap-2 mb-2">
            <i class="bi bi-clock-history" style="color: var(--ink-400);"></i>
            <span class="section-label">Recently viewed</span>
            <span class="pill pill-muted">from cookie</span>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <c:forEach var="r" items="${recentSlots}">
                <a href="confirmBooking.jsp?slotId=${r.slotId}" class="recent-chip">
                    <i class="bi ${r.vehicleType eq 'Shared Bike' ? 'bi-bicycle' : 'bi-bus-front'}"></i>
                    <span>${r.route}</span>
                    <span style="color: var(--ink-400);">
                        <fmt:formatDate value="${r.slotTime}" pattern="hh:mm a"/>
                    </span>
                </a>
            </c:forEach>
        </div>
    </div>
</c:if>

<!-- Filter + search: pure client-side, applied instantly by app.js -->
<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3">
    <div class="chip-row">
        <button class="chip active" data-filter="all" type="button">
            All <span class="count">${slots.size()}</span>
        </button>
        <button class="chip" data-filter="EV Shuttle" type="button">
            <i class="bi bi-bus-front me-1"></i>Shuttle <span class="count">${shuttleCount}</span>
        </button>
        <button class="chip" data-filter="Shared Bike" type="button">
            <i class="bi bi-bicycle me-1"></i>Bike <span class="count">${bikeCount}</span>
        </button>
    </div>

    <div class="position-relative" style="min-width: 250px;">
        <i class="bi bi-search position-absolute top-50 translate-middle-y ms-3"
           style="color: var(--ink-400); font-size:.9rem;"></i>
        <input type="search" id="slotSearch" class="form-control ps-5"
               placeholder="Search a route or stop..." aria-label="Search routes">
    </div>
</div>

<div class="d-flex flex-column gap-3" data-reveal>
    <c:forEach var="slot" items="${slots}">
        <div class="slot-card ${slot.remainingCapacity le 0 ? 'is-full' : ''}"
             data-slot
             data-slot-id="${slot.slotId}"
             data-type="${slot.vehicleType}"
             data-search="${slot.route} ${slot.vehicleType}">

            <span class="vehicle-icon ${slot.vehicleType eq 'Shared Bike' ? 'bike' : 'shuttle'}">
                <i class="bi ${slot.vehicleType eq 'Shared Bike' ? 'bi-bicycle' : 'bi-bus-front'}"></i>
            </span>

            <div class="min-w-0">
                <%-- Route rendered as a journey: origin -> destination --%>
                <c:set var="parts" value="${fn:split(slot.route, '->')}"/>
                <div class="journey mb-2">
                    <span class="node"></span>
                    <span class="stop">${fn:trim(parts[0])}</span>
                    <span class="track"></span>
                    <span class="node hollow"></span>
                    <span class="stop">${fn:trim(parts[1])}</span>
                </div>

                <div class="meta-row">
                    <span class="meta">
                        <i class="bi bi-clock"></i>
                        <fmt:formatDate value="${slot.slotTime}" pattern="hh:mm a"/>
                        &middot;
                        <fmt:formatDate value="${slot.slotTime}" pattern="EEE dd MMM"/>
                    </span>
                    <span class="meta"><i class="bi bi-signpost-2"></i>${slot.distanceKm} km</span>
                    <span class="meta"><i class="bi bi-cloud-check"></i>saves ${slot.co2SavedKg} kg</span>
                    <span class="pill pill-eco" data-departs="${slot.slotTime.time}">&nbsp;</span>
                </div>
            </div>

            <div class="capacity ${slot.remainingCapacity le 0 ? 'full' : (slot.almostFull ? 'warn' : '')}">
                <div class="d-flex justify-content-between align-items-center mb-1">
                    <c:choose>
                        <c:when test="${slot.remainingCapacity le 0}">
                            <span class="pill pill-full"><i class="bi bi-slash-circle"></i>Full</span>
                        </c:when>
                        <c:when test="${slot.almostFull}">
                            <span class="pill pill-soon">Only ${slot.remainingCapacity} left</span>
                        </c:when>
                        <c:otherwise>
                            <small style="color: var(--ink-600);">
                                <strong>${slot.remainingCapacity}</strong> of ${slot.capacity} free
                            </small>
                        </c:otherwise>
                    </c:choose>
                </div>
                <div class="bar">
                    <div class="fill" data-fill="${slot.fillPercent}"></div>
                </div>
            </div>

            <div class="slot-action">
                <c:choose>
                    <c:when test="${slot.remainingCapacity > 0}">
                        <a class="btn btn-primary px-4" href="confirmBooking.jsp?slotId=${slot.slotId}">
                            Book <i class="bi bi-arrow-right ms-1"></i>
                        </a>
                    </c:when>
                    <c:otherwise>
                        <button class="btn btn-outline-secondary px-4" disabled>Full</button>
                    </c:otherwise>
                </c:choose>
            </div>
        </div>
    </c:forEach>
</div>

<div id="noMatches" class="empty-state" style="display:none;">
    <div class="glyph"><i class="bi bi-search"></i></div>
    <p class="text-secondary mt-3 mb-0">No slots match that search.</p>
</div>

<p class="small mt-4 mb-0" style="color: var(--ink-400);">
    <i class="bi bi-info-circle me-1"></i>
    Savings are estimated against an average petrol car (0.192 kg CO<sub>2</sub>/km).
</p>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
