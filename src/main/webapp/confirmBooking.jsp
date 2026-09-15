<%@ include file="/WEB-INF/jspf/authGuard.jspf" %>
<%@ page import="com.woxsen.greenmobility.dao.SlotDAO" %>
<%@ page import="com.woxsen.greenmobility.model.VehicleSlot" %>
<%@ page import="com.woxsen.greenmobility.util.CarbonCalculator" %>
<%@ page import="com.woxsen.greenmobility.util.CookieUtil" %>
<%@ page import="java.math.BigDecimal" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    String pageTitle = "Confirm Booking";
    int slotId = Integer.parseInt(request.getParameter("slotId"));
    VehicleSlot slot = new SlotDAO().findById(slotId);

    if (slot == null) {
        response.sendRedirect(request.getContextPath() + "/availability.jsp?status=error&msg=That slot no longer exists.");
        return;
    }
    if (slot.isFull()) {
        response.sendRedirect(request.getContextPath() + "/availability.jsp?status=error&msg=Sorry, that slot just filled up.");
        return;
    }

    // COOKIE: remember that this slot was looked at, so the browse page can offer
    // it again on a later visit (persists beyond this session).
    CookieUtil.pushRecentSlot(request, response, slotId);

    BigDecimal estimatedSavings = CarbonCalculator.savedKg(slot.getVehicleType(), slot.getDistanceKm());

    // Same distance in a private car, for the side-by-side comparison below.
    BigDecimal carEmissions = slot.getDistanceKm().multiply(new BigDecimal("0.192"))
            .setScale(2, java.math.RoundingMode.HALF_UP);

    request.setAttribute("slot", slot);
    request.setAttribute("estimatedSavings", estimatedSavings);
    request.setAttribute("carEmissions", carEmissions);
%>
<%@ include file="/WEB-INF/jspf/header.jspf" %>

<nav aria-label="breadcrumb">
    <ol class="breadcrumb small">
        <li class="breadcrumb-item"><a href="availability.jsp" class="text-decoration-none">Browse slots</a></li>
        <li class="breadcrumb-item active">Confirm</li>
    </ol>
</nav>

<h1 class="page-title text-forest mb-1">Confirm your booking</h1>
<p class="text-secondary mb-4">One last look before we reserve your seat.</p>

<div class="row g-3">
    <div class="col-lg-7">
        <div class="card p-4 h-100">
            <div class="d-flex align-items-center gap-3 mb-4">
                <span class="vehicle-icon lg ${slot.vehicleType eq 'Shared Bike' ? 'bike' : 'shuttle'}">
                    <i class="bi ${slot.vehicleType eq 'Shared Bike' ? 'bi-bicycle' : 'bi-bus-front'}"></i>
                </span>
                <div>
                    <div class="section-label mb-1">${slot.vehicleType}</div>
                    <span class="pill pill-eco" data-departs="${slot.slotTime.time}">&nbsp;</span>
                </div>
            </div>

            <c:set var="parts" value="${fn:split(slot.route, '->')}"/>
            <div class="journey lg mb-4 pb-4" style="border-bottom: 1px solid var(--border);">
                <span class="node"></span>
                <span class="stop">${fn:trim(parts[0])}</span>
                <span class="track"></span>
                <span class="node hollow"></span>
                <span class="stop">${fn:trim(parts[1])}</span>
            </div>

            <div class="row g-3">
                <div class="col-sm-6">
                    <div class="section-label mb-1">Departs</div>
                    <div class="fw-semibold">
                        <fmt:formatDate value="${slot.slotTime}" pattern="EEEE dd MMM"/><br>
                        <fmt:formatDate value="${slot.slotTime}" pattern="hh:mm a"/>
                    </div>
                </div>
                <div class="col-sm-3">
                    <div class="section-label mb-1">Distance</div>
                    <div class="fw-semibold">${slot.distanceKm} km</div>
                </div>
                <div class="col-sm-3">
                    <div class="section-label mb-1">Seats left</div>
                    <div class="fw-semibold ${slot.almostFull ? 'text-warning-emphasis' : ''}">
                        ${slot.remainingCapacity} / ${slot.capacity}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-lg-5">
        <div class="stat-tile tile-dark h-100 d-flex flex-column justify-content-center text-center p-4">
            <div class="section-label mb-2" style="color: rgba(255,255,255,.6);">Your impact</div>
            <div class="stat-value" data-count="${estimatedSavings}" data-decimals="2" data-suffix=" kg">0</div>
            <div class="stat-label">CO<sub>2</sub> saved on this trip</div>

            <div class="mt-4 pt-3" style="border-top: 1px solid rgba(255,255,255,.16);">
                <div class="d-flex justify-content-between align-items-center small mb-2">
                    <span style="color: rgba(255,255,255,.72);">
                        <i class="bi bi-car-front me-1"></i>Private car
                    </span>
                    <strong>${carEmissions} kg</strong>
                </div>
                <div class="d-flex justify-content-between align-items-center small">
                    <span style="color: rgba(255,255,255,.72);">
                        <i class="bi ${slot.vehicleType eq 'Shared Bike' ? 'bi-bicycle' : 'bi-bus-front'} me-1"></i>
                        This trip
                    </span>
                    <strong style="color: var(--lime);">
                        ${carEmissions - estimatedSavings} kg
                    </strong>
                </div>
            </div>
        </div>
    </div>
</div>

<form method="post" action="processBooking.jsp" class="d-flex flex-column gap-3 mt-4" data-busy>
    <input type="hidden" name="slotId" value="${slot.slotId}">

    <%-- Explicit choice, not a silent auto-spend: a student who has a voucher
         may still want to save it for a different trip, so this defaults to
         checked (most people booking right now want to use one) but can be
         unchecked. Only rendered at all when there's actually a voucher to
         offer. --%>
    <c:if test="${student.freeRideCredits > 0}">
        <div class="form-check p-3"
             style="background: var(--forest-50); border: 1px dashed var(--forest-200); border-radius: var(--r-md);">
            <input class="form-check-input" type="checkbox" id="useVoucher" name="useVoucher" value="true" checked>
            <label class="form-check-label" for="useVoucher">
                <i class="bi bi-gift-fill text-success me-1"></i>
                Use a free ride voucher for this booking
                <span class="text-muted small">(you have ${student.freeRideCredits} available)</span>
            </label>
        </div>
    </c:if>

    <div class="d-flex flex-wrap gap-2">
        <button type="submit" class="btn btn-primary btn-lg px-4">
            <i class="bi bi-check-lg me-1"></i>Confirm booking
        </button>
        <a href="availability.jsp" class="btn btn-outline-secondary btn-lg">Cancel</a>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/footer.jspf" %>
